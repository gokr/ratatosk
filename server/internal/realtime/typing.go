package realtime

import (
	"sync"
	"time"
)

// typingTTL is how long a typing indicator stays lit without a refresh. The
// client re-sends every couple of seconds while the user keeps typing, so this
// only fires for someone who stopped mid-sentence and closed the tab.
const typingTTL = 6 * time.Second

// Typing turns "user is typing" pings into start/stop transitions, so a lost
// stop (crash, dropped connection) cannot leave a blinking indicator forever.
type Typing struct {
	ttl      time.Duration
	onExpire func(convID, userID, displayName string)

	mu     sync.Mutex
	timers map[string]*time.Timer
}

// NewTyping returns a tracker whose onExpire publishes the stop event.
func NewTyping(onExpire func(convID, userID, displayName string)) *Typing {
	return &Typing{ttl: typingTTL, onExpire: onExpire, timers: map[string]*time.Timer{}}
}

func typingKey(convID, userID string) string { return convID + "\x00" + userID }

// Start (re)arms the expiry timer for a typing user. The caller publishes the
// start event itself; this only guarantees a matching stop.
func (t *Typing) Start(convID, userID, displayName string) {
	key := typingKey(convID, userID)
	t.mu.Lock()
	defer t.mu.Unlock()
	if timer, ok := t.timers[key]; ok {
		timer.Stop()
	}
	t.timers[key] = time.AfterFunc(t.ttl, func() {
		t.mu.Lock()
		delete(t.timers, key)
		t.mu.Unlock()
		if t.onExpire != nil {
			t.onExpire(convID, userID, displayName)
		}
	})
}

// Stop cancels a pending expiry after an explicit stop event.
func (t *Typing) Stop(convID, userID string) {
	key := typingKey(convID, userID)
	t.mu.Lock()
	defer t.mu.Unlock()
	if timer, ok := t.timers[key]; ok {
		timer.Stop()
		delete(t.timers, key)
	}
}
