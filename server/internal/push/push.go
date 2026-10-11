// Package push delivers privacy-preserving Web Push outside the message hot path.
package push

import (
	"context"
	"crypto/ecdh"
	"encoding/base64"
	"errors"
	"io"
	"net/http"
	"net/url"
	"sync"
	"time"

	webpush "github.com/SherClockHolmes/webpush-go"
	"github.com/gokr/ratatosk/server/internal/store"
)

type Repository interface {
	PutPushSubscription(*store.PushSubscription) error
	PushSubscriptionsOf(string) ([]*store.PushSubscription, error)
	DeletePushSubscription(endpoint, userID, sessionToken string) error
	SessionByToken(string, time.Time) (*store.Session, error)
	ConversationByID(string) (*store.Conversation, error)
}

type Config struct{ PublicKey, PrivateKey, Contact string }

// Validate disables push when entirely unconfigured, but refuses partial or
// inconsistent credentials. Keys are operator-managed, never regenerated.
func (c Config) Validate() error {
	if c == (Config{}) {
		return nil
	}
	pub, err := base64.RawURLEncoding.DecodeString(c.PublicKey)
	if err != nil {
		return errors.New("invalid VAPID public key")
	}
	priv, err := base64.RawURLEncoding.DecodeString(c.PrivateKey)
	if err != nil {
		return errors.New("invalid VAPID private key")
	}
	key, err := ecdh.P256().NewPrivateKey(priv)
	if err != nil || base64.RawURLEncoding.EncodeToString(key.PublicKey().Bytes()) != c.PublicKey || len(pub) != 65 {
		return errors.New("VAPID keys do not match")
	}
	u, err := url.Parse(c.Contact)
	if err != nil || !((u.Scheme == "mailto" && u.Opaque != "") || (u.Scheme == "https" && u.Hostname() != "")) {
		return errors.New("VAPID contact must be mailto: or https:")
	}
	return nil
}

func ValidateKeys(p256dh, auth string) error {
	p, err := base64.RawURLEncoding.DecodeString(p256dh)
	if err != nil {
		return errors.New("invalid p256dh key")
	}
	if _, err := ecdh.P256().NewPublicKey(p); err != nil {
		return errors.New("invalid p256dh key")
	}
	a, err := base64.RawURLEncoding.DecodeString(auth)
	if err != nil || len(a) != 16 {
		return errors.New("invalid auth key")
	}
	return nil
}

type Sender interface {
	Send(context.Context, *store.PushSubscription, []byte) (int, error)
}
type webSender struct {
	cfg    Config
	client *http.Client
}

func (s *webSender) Send(ctx context.Context, sub *store.PushSubscription, payload []byte) (int, error) {
	resp, err := webpush.SendNotificationWithContext(ctx, payload, &webpush.Subscription{Endpoint: sub.Endpoint, Keys: webpush.Keys{P256dh: sub.P256DH, Auth: sub.Auth}}, &webpush.Options{HTTPClient: s.client, Subscriber: s.cfg.Contact, VAPIDPublicKey: s.cfg.PublicKey, VAPIDPrivateKey: s.cfg.PrivateKey, TTL: 300})
	if err != nil {
		return 0, err
	}
	defer resp.Body.Close()
	_, _ = io.Copy(io.Discard, io.LimitReader(resp.Body, 4096))
	return resp.StatusCode, nil
}

type event struct{ id, conversation, sender string }
type Worker struct {
	cfg    Config
	repo   Repository
	sender Sender
	queue  chan event
	mu     sync.Mutex
	seen   map[string]struct{}
	order  []string
}

func New(cfg Config, repo Repository, sender Sender) (*Worker, error) {
	if err := cfg.Validate(); err != nil {
		return nil, err
	}
	if sender == nil {
		sender = &webSender{cfg, SafeClient()}
	}
	return &Worker{cfg: cfg, repo: repo, sender: sender, queue: make(chan event, 256), seen: make(map[string]struct{})}, nil
}
func (w *Worker) Enabled() bool { return w != nil && w.cfg.PublicKey != "" }
func (w *Worker) PublicKey() string {
	if !w.Enabled() {
		return ""
	}
	return w.cfg.PublicKey
}

// Notify never blocks on network or repository I/O. Overflow is best-effort:
// the durable message remains available on the next sync.
func (w *Worker) Notify(id, conversation, sender string) bool {
	if !w.Enabled() {
		return false
	}
	w.mu.Lock()
	defer w.mu.Unlock()
	if _, exists := w.seen[id]; exists {
		return false
	}
	select {
	case w.queue <- event{id, conversation, sender}:
		w.seen[id] = struct{}{}
		w.order = append(w.order, id)
		if len(w.order) > 4096 {
			delete(w.seen, w.order[0])
			w.order = w.order[1:]
		}
		return true
	default:
		return false
	}
}
func (w *Worker) Run(ctx context.Context) {
	if !w.Enabled() {
		return
	}
	for {
		select {
		case <-ctx.Done():
			return
		case e := <-w.queue:
			w.deliver(ctx, e)
		}
	}
}
func (w *Worker) eligible(sub *store.PushSubscription, e event) bool {
	session, err := w.repo.SessionByToken(sub.SessionToken, time.Now())
	if err != nil || session.UserID != sub.UserID {
		return false
	}
	c, err := w.repo.ConversationByID(e.conversation)
	if err != nil {
		return false
	}
	m := c.Members[sub.UserID]
	return m != nil && !m.Muted && sub.UserID != e.sender
}
func (w *Worker) deliver(ctx context.Context, e event) {
	c, err := w.repo.ConversationByID(e.conversation)
	if err != nil {
		return
	}
	for user, m := range c.Members {
		if user == e.sender || m.Muted {
			continue
		}
		subs, err := w.repo.PushSubscriptionsOf(user)
		if err != nil {
			continue
		}
		for _, sub := range subs {
			for attempt := 0; attempt < 3; attempt++ {
				if ctx.Err() != nil || !w.eligible(sub, e) {
					break
				}
				sendCtx, cancel := context.WithTimeout(ctx, 10*time.Second)
				status, err := w.sender.Send(sendCtx, sub, []byte(`{"title":"Ratatosk","body":"New message"}`))
				cancel()
				if status == http.StatusGone || status == http.StatusNotFound {
					_ = w.repo.DeletePushSubscription(sub.Endpoint, sub.UserID, sub.SessionToken)
					break
				}
				if err == nil && status >= 200 && status < 300 {
					break
				}
				if err == nil && status != 429 && status < 500 {
					break
				}
				if attempt == 2 {
					break
				}
				select {
				case <-ctx.Done():
					return
				case <-time.After(time.Duration(attempt+1) * time.Second):
				}
			}
		}
	}
}
