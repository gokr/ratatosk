// Package realtime carries everything that is pushed to clients: the fan-out
// hub behind ChatService.Subscribe, the presence tracker and typing timers.
//
// Nothing here is persisted. A subscriber that cannot keep up is disconnected
// rather than silently losing events: the client reconnects, re-syncs from the
// store and ends up consistent. Losing an event without telling anyone would
// be the one unrecoverable failure mode of a chat client.
package realtime

import (
	"sync"
	"sync/atomic"

	ratatoskv1 "github.com/gokr/ratatosk/server/gen/ratatosk/v1"
)

// subBuffer is how many events a single connection may fall behind by. A
// client that exceeds it is dropped: 256 frames is already several seconds of
// a busy group chat, and the recovery path (resync) is cheap.
const subBuffer = 256

// Hub routes events to the live streams of each user.
type Hub struct {
	mu   sync.Mutex
	subs map[string]map[*Sub]struct{}
	seq  atomic.Int64
}

// NewHub returns an empty hub.
func NewHub() *Hub {
	return &Hub{subs: map[string]map[*Sub]struct{}{}}
}

// NextSeq returns the next server-wide event sequence number. It orders a
// client's event log; it is not a per-conversation position.
func (h *Hub) NextSeq() int64 { return h.seq.Add(1) }

// Sub is one live Subscribe stream.
type Sub struct {
	userID   string
	events   chan *ratatoskv1.Event
	overflow chan struct{}
	once     sync.Once
}

// Subscribe registers a stream and reports whether it is the user's first live
// connection (the hub's callers use that for presence transitions).
func (h *Hub) Subscribe(userID string) (*Sub, bool) {
	s := &Sub{
		userID:   userID,
		events:   make(chan *ratatoskv1.Event, subBuffer),
		overflow: make(chan struct{}),
	}
	h.mu.Lock()
	defer h.mu.Unlock()
	set := h.subs[userID]
	if set == nil {
		set = map[*Sub]struct{}{}
		h.subs[userID] = set
	}
	set[s] = struct{}{}
	return s, len(set) == 1
}

// Unsubscribe removes a stream, reporting whether it was the user's last one.
func (h *Hub) Unsubscribe(s *Sub) (last bool) {
	h.mu.Lock()
	defer h.mu.Unlock()
	set := h.subs[s.userID]
	if set == nil {
		return false
	}
	delete(set, s)
	if len(set) == 0 {
		delete(h.subs, s.userID)
		return true
	}
	return false
}

// Connections counts a user's live streams.
func (h *Hub) Connections(userID string) int {
	h.mu.Lock()
	defer h.mu.Unlock()
	return len(h.subs[userID])
}

// Send delivers an event to every stream of one user.
func (h *Hub) Send(userID string, ev *ratatoskv1.Event) {
	if ev == nil {
		return
	}
	for _, s := range h.targets(userID) {
		s.send(ev)
	}
}

// SendMany delivers a distinct event to each of several users. build is called
// once per user because most events are viewer-specific: unread counts and the
// conversation's title differ per recipient. Returning nil skips that user.
func (h *Hub) SendMany(userIDs []string, build func(userID string) *ratatoskv1.Event) {
	for _, id := range userIDs {
		h.Send(id, build(id))
	}
}

func (h *Hub) targets(userID string) []*Sub {
	h.mu.Lock()
	defer h.mu.Unlock()
	set := h.subs[userID]
	if len(set) == 0 {
		return nil
	}
	out := make([]*Sub, 0, len(set))
	for s := range set {
		out = append(out, s)
	}
	return out
}

func (s *Sub) send(ev *ratatoskv1.Event) {
	select {
	case s.events <- ev:
	default:
		// The stream is too far behind to catch up in a bounded buffer; tell
		// the handler to end it so the client resyncs from the store.
		s.once.Do(func() { close(s.overflow) })
	}
}

// Events is the channel the stream handler reads.
func (s *Sub) Events() <-chan *ratatoskv1.Event { return s.events }

// Overflow is closed when this stream fell too far behind and must be
// restarted by the client.
func (s *Sub) Overflow() <-chan struct{} { return s.overflow }
