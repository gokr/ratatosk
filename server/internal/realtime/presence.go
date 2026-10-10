package realtime

import (
	"context"
	"log/slog"
	"sync"
	"time"

	"google.golang.org/protobuf/types/known/timestamppb"

	ratatoskv1 "github.com/gokr/ratatosk/server/gen/ratatosk/v1"
	"github.com/gokr/ratatosk/server/internal/store"
)

// Presence thresholds. A connected user is AWAY after awayAfter without an
// authenticated call and OFFLINE the moment their last stream drops.
const (
	defaultAwayAfter = 5 * time.Minute
	presenceTick     = 10 * time.Second
)

// Tracker derives presence from live connections plus recent activity, and
// pushes transitions to everyone who can see the user.
type Tracker struct {
	store      *store.Store
	hub        *Hub
	recipients func(userID string) []string
	awayAfter  time.Duration
	log        *slog.Logger

	mu         sync.Mutex
	conns      map[string]int
	lastActive map[string]time.Time
	// state caches the last broadcast value so the ticker only sends changes.
	state map[string]ratatoskv1.Presence
}

// NewTracker wires a tracker to the store (for LastSeen) and the hub. The
// recipient function (who may observe a user) is set later with SetRecipients,
// because it lives in the service layer which is built on top of the tracker.
func NewTracker(st *store.Store, hub *Hub, recipients func(string) []string, awayAfter time.Duration, log *slog.Logger) *Tracker {
	if awayAfter <= 0 {
		awayAfter = defaultAwayAfter
	}
	if log == nil {
		log = slog.Default()
	}
	return &Tracker{
		store:      st,
		hub:        hub,
		recipients: recipients,
		awayAfter:  awayAfter,
		log:        log,
		conns:      map[string]int{},
		lastActive: map[string]time.Time{},
		state:      map[string]ratatoskv1.Presence{},
	}
}

// SetRecipients installs the visibility rule: which users are allowed to
// observe a given user's presence. Until it is set, transitions are not
// broadcast (nothing can see them).
func (t *Tracker) SetRecipients(fn func(string) []string) {
	t.mu.Lock()
	defer t.mu.Unlock()
	t.recipients = fn
}

// Connect records a new live stream for a user.
func (t *Tracker) Connect(userID string) {
	now := time.Now()
	t.mu.Lock()
	t.conns[userID]++
	t.lastActive[userID] = now
	t.mu.Unlock()
	t.store.SetLastSeen(userID, now)
	t.broadcast(userID)
}

// Disconnect removes a live stream; the user goes offline with their last one.
func (t *Tracker) Disconnect(userID string) {
	now := time.Now()
	t.mu.Lock()
	if t.conns[userID] > 0 {
		t.conns[userID]--
	}
	if t.conns[userID] == 0 {
		delete(t.conns, userID)
		delete(t.lastActive, userID)
	}
	t.mu.Unlock()
	t.store.SetLastSeen(userID, now)
	t.broadcast(userID)
}

// Active notes authenticated activity, which is what separates ONLINE from
// AWAY. Cheap enough to call on every request.
func (t *Tracker) Active(userID string) {
	now := time.Now()
	t.mu.Lock()
	_, tracked := t.conns[userID]
	if tracked {
		t.lastActive[userID] = now
	}
	t.mu.Unlock()
	if tracked {
		t.broadcast(userID)
	}
}

// Presence reports the user's current state.
func (t *Tracker) Presence(userID string) ratatoskv1.Presence {
	t.mu.Lock()
	defer t.mu.Unlock()
	return t.computeLocked(userID, time.Now())
}

func (t *Tracker) computeLocked(userID string, now time.Time) ratatoskv1.Presence {
	if t.conns[userID] == 0 {
		return ratatoskv1.Presence_PRESENCE_OFFLINE
	}
	last, ok := t.lastActive[userID]
	if !ok || now.Sub(last) > t.awayAfter {
		return ratatoskv1.Presence_PRESENCE_AWAY
	}
	return ratatoskv1.Presence_PRESENCE_ONLINE
}

// Run keeps an idle connection from looking online forever: it recomputes
// presence periodically and broadcasts changes.
func (t *Tracker) Run(ctx context.Context) {
	tick := time.NewTicker(presenceTick)
	defer tick.Stop()
	for {
		select {
		case <-ctx.Done():
			return
		case <-tick.C:
			t.mu.Lock()
			ids := make([]string, 0, len(t.conns))
			for id := range t.conns {
				ids = append(ids, id)
			}
			t.mu.Unlock()
			for _, id := range ids {
				t.broadcast(id)
			}
		}
	}
}

// broadcast publishes the user's presence if it changed since the last time.
func (t *Tracker) broadcast(userID string) {
	now := time.Now()
	t.mu.Lock()
	state := t.computeLocked(userID, now)
	if old, ok := t.state[userID]; ok && old == state {
		t.mu.Unlock()
		return
	}
	t.state[userID] = state
	t.mu.Unlock()

	lastSeen := now
	if u, err := t.store.UserByID(userID); err == nil {
		lastSeen = u.LastSeen
	}
	recipients := t.recipients
	if recipients == nil {
		return
	}
	t.hub.SendMany(recipients(userID), func(string) *ratatoskv1.Event {
		return &ratatoskv1.Event{
			Seq: t.hub.NextSeq(),
			At:  timestamppb.New(now),
			Payload: &ratatoskv1.Event_Presence{
				Presence: &ratatoskv1.PresenceEvent{
					UserId:   userID,
					Presence: state,
					LastSeen: timestamppb.New(lastSeen),
				},
			},
		}
	})
}
