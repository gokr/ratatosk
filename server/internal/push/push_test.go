package push

import (
	"context"
	"errors"
	"net/http"
	"net/netip"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/gokr/ratatosk/server/internal/store"
)

// --- fakes ---------------------------------------------------------------

// fakeSession is a session that may be expired or revoked, which is how a
// signed-out device must stop receiving notifications.
type fakeSession struct {
	userID    string
	expiresAt time.Time
	valid     bool
}

type fakeRepo struct {
	mu           sync.Mutex
	sessions     map[string]fakeSession
	conversation *store.Conversation
	subs         map[string][]*store.PushSubscription
	deleted      []string
	put          []*store.PushSubscription
}

func (r *fakeRepo) PutPushSubscription(s *store.PushSubscription) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.put = append(r.put, s)
	return nil
}

func (r *fakeRepo) PushSubscriptionsOf(userID string) ([]*store.PushSubscription, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	return append([]*store.PushSubscription(nil), r.subs[userID]...), nil
}

func (r *fakeRepo) DeletePushSubscription(endpoint, userID, sessionToken string) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.deleted = append(r.deleted, endpoint)
	return nil
}

func (r *fakeRepo) SessionByToken(token string, now time.Time) (*store.Session, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	s, ok := r.sessions[token]
	if !ok || !s.valid {
		return nil, store.ErrNotFound
	}
	if !s.expiresAt.IsZero() && !now.Before(s.expiresAt) {
		return nil, store.ErrNotFound
	}
	return &store.Session{Token: token, UserID: s.userID, ExpiresAt: s.expiresAt}, nil
}

func (r *fakeRepo) ConversationByID(id string) (*store.Conversation, error) {
	if r.conversation == nil || r.conversation.ID != id {
		return nil, store.ErrNotFound
	}
	return r.conversation, nil
}

// fakeSender records what would leave the server and can be told to fail.
type fakeSender struct {
	mu      sync.Mutex
	calls   []fakeCall
	status  int
	err     error
	statusF func(endpoint string) int
}

type fakeCall struct {
	endpoint string
	payload  string
}

func (s *fakeSender) Send(_ context.Context, sub *store.PushSubscription, payload []byte) (int, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.calls = append(s.calls, fakeCall{endpoint: sub.Endpoint, payload: string(payload)})
	if s.statusF != nil {
		return s.statusF(sub.Endpoint), s.err
	}
	if s.status == 0 {
		return http.StatusCreated, s.err
	}
	return s.status, s.err
}

func (s *fakeSender) sent() []fakeCall {
	s.mu.Lock()
	defer s.mu.Unlock()
	return append([]fakeCall(nil), s.calls...)
}

// A real VAPID pair, so Config.Validate is exercised with key material rather
// than a stub. The public half is P-256 uncompressed.
const (
	testVAPIDPrivate = "tTK2ll3yrr1MEAyPUHmATW1CaHsZtVGSbqD2Ru8uzaE"
	testVAPIDPublic  = "BJdE6ZZWFudyO_s8bU_geA1MzozxlvVjGj--h2SKoI0fjhHJ2Dyy5SfD9nXvgWSn7LNsbY66VxCPPi0WvJ6MDdg"
	testKey          = testVAPIDPublic
)

// pushKeys returns a matching VAPID pair, so Config.Validate is exercised with
// real key material rather than a stub.
func pushKeys(t *testing.T) Config {
	t.Helper()
	return Config{
		PublicKey:  testVAPIDPublic,
		PrivateKey: testVAPIDPrivate,
		Contact:    "mailto:ops@example.test",
	}
}

// group builds a conversation with members, one of whom may be muted.
func group(convID string, muted ...string) *store.Conversation {
	c := &store.Conversation{ID: convID, Kind: store.KindGroup, Members: map[string]*store.Member{}}
	for _, id := range []string{"u-sender", "u-recipient", "u-other"} {
		c.Members[id] = &store.Member{UserID: id}
	}
	for _, id := range muted {
		c.Members[id].Muted = true
	}
	return c
}

func subFor(user, session, endpoint string) *store.PushSubscription {
	return &store.PushSubscription{
		Endpoint: endpoint, UserID: user, SessionToken: session,
		P256DH: testKey, Auth: "AAAAAAAAAAAAAAAAAAAAAA",
	}
}

func newTestWorker(t *testing.T, repo *fakeRepo, sender *fakeSender) *Worker {
	t.Helper()
	w, err := New(pushKeys(t), repo, sender)
	if err != nil {
		t.Fatalf("new worker: %v", err)
	}
	return w
}

// --- config --------------------------------------------------------------

func TestUnconfiguredPushIsDisabled(t *testing.T) {
	w, err := New(Config{}, &fakeRepo{}, &fakeSender{})
	if err != nil {
		t.Fatalf("new: %v", err)
	}
	if w.Enabled() || w.PublicKey() != "" {
		t.Fatal("push should be off with no VAPID keys")
	}
	if w.Notify("m1", "c1", "u-1") {
		t.Fatal("a disabled worker must not accept a notification")
	}
}

// A partially configured server is a mistake, not a mode: half a key pair would
// otherwise rotate everyone's subscriptions on every restart.
func TestPartialVAPIDConfigRefusesToStart(t *testing.T) {
	if _, err := New(Config{PublicKey: testVAPIDPublic}, &fakeRepo{}, &fakeSender{}); err == nil {
		t.Fatal("a public key with no private key was accepted")
	}
	if _, err := New(Config{PrivateKey: testVAPIDPrivate, Contact: "mailto:a@b.c"}, &fakeRepo{}, &fakeSender{}); err == nil {
		t.Fatal("a private key with no public key was accepted")
	}
	// A mismatched pair is worse: signatures would be rejected by the push
	// service with no obvious cause.
	if _, err := New(Config{
		PublicKey: testVAPIDPublic, PrivateKey: strings.Repeat("AA", 32),
		Contact: "mailto:a@b.c",
	}, &fakeRepo{}, &fakeSender{}); err == nil {
		t.Fatal("mismatched VAPID keys were accepted")
	}
	// The contact must be something a push service can act on.
	if _, err := New(Config{
		PublicKey: testVAPIDPublic, PrivateKey: testVAPIDPrivate, Contact: "nonsense",
	}, &fakeRepo{}, &fakeSender{}); err == nil {
		t.Fatal("an invalid VAPID contact was accepted")
	}
}

// --- delivery ------------------------------------------------------------

// The notification body is fixed. It must not carry who wrote, what was said,
// or which conversation it was — the push service is a third party.
func TestPayloadRevealsNothingAboutTheMessage(t *testing.T) {
	repo := &fakeRepo{
		sessions:     map[string]fakeSession{"s-recipient": {userID: "u-recipient", valid: true}},
		conversation: group("c1"),
		subs:         map[string][]*store.PushSubscription{"u-recipient": {subFor("u-recipient", "s-recipient", "https://push.example/r")}},
	}
	sender := &fakeSender{}
	w := newTestWorker(t, repo, sender)

	w.deliver(context.Background(), event{id: "m1", conversation: "c1", sender: "u-sender"})

	calls := sender.sent()
	if len(calls) != 1 {
		t.Fatalf("sent %d notifications, want 1", len(calls))
	}
	payload := calls[0].payload
	for _, secret := range []string{"u-sender", "c1", "m1"} {
		if strings.Contains(payload, secret) {
			t.Errorf("payload mentions %q: %s", secret, payload)
		}
	}
	if !strings.Contains(payload, "New message") {
		t.Errorf("payload = %s, want a generic message", payload)
	}
}

func TestSenderIsNeverNotifiedOfTheirOwnMessage(t *testing.T) {
	repo := &fakeRepo{
		sessions: map[string]fakeSession{
			"s-sender":    {userID: "u-sender", valid: true},
			"s-recipient": {userID: "u-recipient", valid: true},
		},
		conversation: group("c1"),
		subs: map[string][]*store.PushSubscription{
			"u-sender":    {subFor("u-sender", "s-sender", "https://push.example/sender")},
			"u-recipient": {subFor("u-recipient", "s-recipient", "https://push.example/recipient")},
		},
	}
	sender := &fakeSender{}
	w := newTestWorker(t, repo, sender)

	w.deliver(context.Background(), event{id: "m1", conversation: "c1", sender: "u-sender"})

	for _, call := range sender.sent() {
		if call.endpoint == "https://push.example/sender" {
			t.Fatal("the sender was notified of their own message")
		}
	}
}

func TestMutedConversationIsNotNotified(t *testing.T) {
	repo := &fakeRepo{
		sessions:     map[string]fakeSession{"s-recipient": {userID: "u-recipient", valid: true}},
		conversation: group("c1", "u-recipient"),
		subs:         map[string][]*store.PushSubscription{"u-recipient": {subFor("u-recipient", "s-recipient", "https://push.example/r")}},
	}
	sender := &fakeSender{}
	w := newTestWorker(t, repo, sender)

	w.deliver(context.Background(), event{id: "m1", conversation: "c1", sender: "u-sender"})

	if len(sender.sent()) != 0 {
		t.Fatal("a muted conversation produced a notification")
	}
}

// Signing out must stop notifications immediately, not at token expiry.
func TestSignedOutSessionIsNotNotified(t *testing.T) {
	repo := &fakeRepo{
		// Present but no longer valid: the token was revoked.
		sessions:     map[string]fakeSession{"s-recipient": {userID: "u-recipient", valid: false}},
		conversation: group("c1"),
		subs:         map[string][]*store.PushSubscription{"u-recipient": {subFor("u-recipient", "s-recipient", "https://push.example/r")}},
	}
	sender := &fakeSender{}
	w := newTestWorker(t, repo, sender)

	w.deliver(context.Background(), event{id: "m1", conversation: "c1", sender: "u-sender"})

	if len(sender.sent()) != 0 {
		t.Fatal("a revoked session still received a notification")
	}
	if len(repo.deleted) != 0 {
		t.Fatal("a revoked session's subscription should be left for the owner to clean up")
	}
}

func TestExpiredSessionIsNotNotified(t *testing.T) {
	repo := &fakeRepo{
		sessions: map[string]fakeSession{
			"s-recipient": {userID: "u-recipient", valid: true, expiresAt: time.Now().Add(-time.Hour)},
		},
		conversation: group("c1"),
		subs:         map[string][]*store.PushSubscription{"u-recipient": {subFor("u-recipient", "s-recipient", "https://push.example/r")}},
	}
	sender := &fakeSender{}
	w := newTestWorker(t, repo, sender)

	w.deliver(context.Background(), event{id: "m1", conversation: "c1", sender: "u-sender"})

	if len(sender.sent()) != 0 {
		t.Fatal("an expired session still received a notification")
	}
}

// A subscription that the push service says is gone must be dropped, or every
// message pays for it forever.
func TestGoneSubscriptionIsDeleted(t *testing.T) {
	repo := &fakeRepo{
		sessions:     map[string]fakeSession{"s-recipient": {userID: "u-recipient", valid: true}},
		conversation: group("c1"),
		subs:         map[string][]*store.PushSubscription{"u-recipient": {subFor("u-recipient", "s-recipient", "https://push.example/gone")}},
	}
	sender := &fakeSender{status: http.StatusGone}
	w := newTestWorker(t, repo, sender)

	w.deliver(context.Background(), event{id: "m1", conversation: "c1", sender: "u-sender"})

	if len(repo.deleted) != 1 || repo.deleted[0] != "https://push.example/gone" {
		t.Fatalf("deleted = %v, want the gone endpoint", repo.deleted)
	}
	// One attempt, not three: the endpoint is dead.
	if got := len(sender.sent()); got != 1 {
		t.Fatalf("tried %d times against a gone endpoint, want 1", got)
	}
}

// A 404 from a push service means the same thing as 410: no such subscription.
func TestNotFoundSubscriptionIsDeleted(t *testing.T) {
	repo := &fakeRepo{
		sessions:     map[string]fakeSession{"s-recipient": {userID: "u-recipient", valid: true}},
		conversation: group("c1"),
		subs:         map[string][]*store.PushSubscription{"u-recipient": {subFor("u-recipient", "s-recipient", "https://push.example/missing")}},
	}
	sender := &fakeSender{status: http.StatusNotFound}
	w := newTestWorker(t, repo, sender)

	w.deliver(context.Background(), event{id: "m1", conversation: "c1", sender: "u-sender"})

	if len(repo.deleted) != 1 {
		t.Fatalf("deleted = %v, want the missing endpoint removed", repo.deleted)
	}
}

// A transient failure is retried; a permanent client error is not worth
// hammering.
func TestTransientFailureRetriesAndPermanentDoesNot(t *testing.T) {
	cases := []struct {
		name      string
		status    int
		wantTries int
	}{
		{"server error is retried", http.StatusInternalServerError, 3},
		{"rate limit is retried", http.StatusTooManyRequests, 3},
		{"bad request is not retried", http.StatusBadRequest, 1},
		{"success is not retried", http.StatusCreated, 1},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			repo := &fakeRepo{
				sessions:     map[string]fakeSession{"s-recipient": {userID: "u-recipient", valid: true}},
				conversation: group("c1"),
				subs:         map[string][]*store.PushSubscription{"u-recipient": {subFor("u-recipient", "s-recipient", "https://push.example/r")}},
			}
			sender := &fakeSender{status: tc.status}
			w := newTestWorker(t, repo, sender)

			w.deliver(context.Background(), event{id: "m1", conversation: "c1", sender: "u-sender"})

			if got := len(sender.sent()); got != tc.wantTries {
				t.Fatalf("tries = %d, want %d (status %d)", got, tc.wantTries, tc.status)
			}
			if len(repo.deleted) != 0 {
				t.Fatal("a retryable status must not delete the subscription")
			}
		})
	}
}

// A cancelled context stops work promptly: shutdown must not wait out retries.
func TestCancelledContextStopsDelivery(t *testing.T) {
	repo := &fakeRepo{
		sessions:     map[string]fakeSession{"s-recipient": {userID: "u-recipient", valid: true}},
		conversation: group("c1"),
		subs:         map[string][]*store.PushSubscription{"u-recipient": {subFor("u-recipient", "s-recipient", "https://push.example/r")}},
	}
	sender := &fakeSender{status: http.StatusInternalServerError}
	w := newTestWorker(t, repo, sender)

	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	w.deliver(ctx, event{id: "m1", conversation: "c1", sender: "u-sender"})

	if len(sender.sent()) != 0 {
		t.Fatal("delivery continued after the context was cancelled")
	}
}

// A message the server cannot look up (a conversation deleted mid-flight) is
// dropped rather than retried forever.
func TestUnknownConversationSendsNothing(t *testing.T) {
	repo := &fakeRepo{
		sessions: map[string]fakeSession{"s-recipient": {userID: "u-recipient", valid: true}},
		subs:     map[string][]*store.PushSubscription{"u-recipient": {subFor("u-recipient", "s-recipient", "https://push.example/r")}},
	}
	sender := &fakeSender{}
	w := newTestWorker(t, repo, sender)

	w.deliver(context.Background(), event{id: "m1", conversation: "gone", sender: "u-sender"})

	if len(sender.sent()) != 0 {
		t.Fatal("a notification was sent for a missing conversation")
	}
}

// The send path must not block on the network: Notify only enqueues, and a full
// queue drops rather than waiting (the message itself is durable).
func TestNotifyNeverBlocksAndDeduplicates(t *testing.T) {
	w := newTestWorker(t, &fakeRepo{}, &fakeSender{})
	// The worker is not running, so the queue can only fill.
	if !w.Notify("m1", "c1", "u-1") {
		t.Fatal("the first notification was refused")
	}
	if w.Notify("m1", "c1", "u-1") {
		t.Fatal("a duplicate message id was accepted")
	}
	var accepted int
	done := make(chan struct{})
	go func() {
		defer close(done)
		for i := 0; i < 5000; i++ {
			if w.Notify(string(rune('a'+i%26))+string(rune(i)), "c1", "u-1") {
				accepted++
			}
		}
	}()
	select {
	case <-done:
	case <-time.After(5 * time.Second):
		t.Fatal("Notify blocked: the send path must never wait on push")
	}
	if accepted > 260 {
		t.Fatalf("accepted %d notifications into a 256-slot queue", accepted)
	}
}

// --- endpoint validation -------------------------------------------------

func TestEndpointValidationRejectsNonPublicDestinations(t *testing.T) {
	bad := []string{
		"http://push.example/x",            // not https
		"https://127.0.0.1/x",              // loopback
		"https://[::1]/x",                  // loopback, v6
		"https://169.254.169.254/latest",   // link-local metadata
		"https://10.0.0.5/x",               // private
		"https://192.168.1.1/x",            // private
		"https://localhost/x",              // name for loopback
		"https://something.local/x",        // mDNS
		"https://user:pass@push.example/x", // embedded credentials
		"https://push.example:8443/x",      // unexpected port
		"https://push.example/x#fragment",  // fragment
		"nonsense",                         // not a URL
		"",                                 // empty
	}
	ctx := context.Background()
	for _, endpoint := range bad {
		if err := ValidateEndpoint(ctx, endpoint); err == nil {
			t.Errorf("accepted %q, which is not a public HTTPS push endpoint", endpoint)
		}
	}
}

func mustAddr(t *testing.T, raw string) netip.Addr {
	t.Helper()
	return netip.MustParseAddr(raw)
}

func TestPublicIPRejectsSpecialRanges(t *testing.T) {
	// Every address here is either loopback, private, link-local, or one of the
	// special-purpose ranges a request must never be sent to.
	for _, raw := range []string{
		"127.0.0.1", "::1", "10.1.2.3", "172.16.0.1", "192.168.0.1",
		"169.254.169.254", "100.64.0.1", "0.0.0.0", "224.0.0.1",
		"192.0.2.1", "198.51.100.1", "203.0.113.1", "2001:db8::1",
	} {
		if PublicIP(mustAddr(t, raw)) {
			t.Errorf("%s was treated as public", raw)
		}
	}
	for _, raw := range []string{"8.8.8.8", "1.1.1.1", "2606:4700::1111"} {
		if !PublicIP(mustAddr(t, raw)) {
			t.Errorf("%s was treated as non-public", raw)
		}
	}
}

func TestKeyValidation(t *testing.T) {
	if err := ValidateKeys(testKey, "AAAAAAAAAAAAAAAAAAAAAA"); err != nil {
		t.Fatalf("valid keys rejected: %v", err)
	}
	// Not a P-256 point.
	if err := ValidateKeys("AAAAAAAAAAAAAAAAAAAAAA", "AAAAAAAAAAAAAAAAAAAAAA"); err == nil {
		t.Error("a bogus p256dh key was accepted")
	}
	// Auth secret must be exactly 16 bytes.
	if err := ValidateKeys(testKey, "AAAA"); err == nil {
		t.Error("a short auth secret was accepted")
	}
	if err := ValidateKeys(testKey, ""); err == nil {
		t.Error("an empty auth secret was accepted")
	}
	if err := ValidateKeys("", ""); err == nil {
		t.Error("empty keys were accepted")
	}
}

// Errors from the sender are retried like a 5xx: the notification is best
// effort, and a network blip should not cost the wake-up.
func TestSenderErrorIsRetried(t *testing.T) {
	repo := &fakeRepo{
		sessions:     map[string]fakeSession{"s-recipient": {userID: "u-recipient", valid: true}},
		conversation: group("c1"),
		subs:         map[string][]*store.PushSubscription{"u-recipient": {subFor("u-recipient", "s-recipient", "https://push.example/r")}},
	}
	sender := &fakeSender{err: errors.New("connection reset")}
	w := newTestWorker(t, repo, sender)

	w.deliver(context.Background(), event{id: "m1", conversation: "c1", sender: "u-sender"})

	if got := len(sender.sent()); got != 3 {
		t.Fatalf("tries = %d, want 3 after transport errors", got)
	}
}
