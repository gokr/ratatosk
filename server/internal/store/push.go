package store

import (
	"database/sql"
	"time"
)

// PushSubscription is bound to an authenticated account AND session. Its
// endpoint and browser credentials are encrypted at rest, not SQL plaintext.
type PushSubscription struct {
	Endpoint     string
	UserID       string
	SessionToken string
	P256DH       string
	Auth         string
	CreatedAt    time.Time
}

// PutPushSubscription permits credential refresh only by the original owner
// and session. A different session must explicitly remove the old subscription.
func (s *Store) PutPushSubscription(sub *PushSubscription) error {
	if sub == nil || sub.Endpoint == "" || sub.P256DH == "" || sub.Auth == "" {
		return ErrInvalidKey
	}
	return s.write(func(tx *sql.Tx) error {
		sess, e := getRow[Session](s, tx, "sessions", sub.SessionToken)
		if e != nil {
			return e
		}
		if sess.UserID != sub.UserID || (!sess.ExpiresAt.IsZero() && !time.Now().Before(sess.ExpiresAt)) {
			return ErrNotFound
		}
		old, e := getRow[PushSubscription](s, tx, "push_subscriptions", sub.Endpoint)
		if e != nil && e != ErrNotFound {
			return e
		}
		if old != nil && (old.UserID != sub.UserID || old.SessionToken != sub.SessionToken) {
			return ErrAlreadyExists
		}
		copy := *sub
		if old != nil {
			copy.CreatedAt = old.CreatedAt
		} else if copy.CreatedAt.IsZero() {
			copy.CreatedAt = time.Now()
		}
		return s.put(tx, "push_subscriptions", copy.Endpoint, &copy, []string{"owner", "session"}, s.rowID("users", copy.UserID), s.rowID("sessions", copy.SessionToken))
	})
}
func (s *Store) PushSubscriptionsOf(userID string) ([]*PushSubscription, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	tx, e := s.sql.Begin()
	if e != nil {
		return nil, e
	}
	defer tx.Rollback()
	all, e := listRows[PushSubscription](s, tx, "push_subscriptions", "WHERE owner=?", s.rowID("users", userID))
	if e != nil {
		return nil, e
	}
	out := make([]*PushSubscription, 0, len(all))
	for _, v := range all {
		sess, e := getRow[Session](s, tx, "sessions", v.SessionToken)
		if e == ErrNotFound {
			continue
		}
		if e != nil {
			return nil, e
		}
		if sess.UserID == userID && (sess.ExpiresAt.IsZero() || time.Now().Before(sess.ExpiresAt)) {
			out = append(out, v)
		}
	}
	return out, nil
}

// DeletePushSubscription is idempotent. An empty session token is reserved for
// the worker's owner-bound deletion of expired endpoints; never use it for an
// unauthenticated browser request.
func (s *Store) DeletePushSubscription(endpoint, userID, sessionToken string) error {
	return s.write(func(tx *sql.Tx) error {
		old, e := getRow[PushSubscription](s, tx, "push_subscriptions", endpoint)
		if e == ErrNotFound {
			return nil
		}
		if e != nil {
			return e
		}
		if old.UserID != userID || (sessionToken != "" && old.SessionToken != sessionToken) {
			return ErrNotFound
		}
		return s.remove(tx, "push_subscriptions", endpoint)
	})
}
