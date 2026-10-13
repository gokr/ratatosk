package store

import (
	"database/sql"
	"time"
)

// OAuthTicket authorizes one browser redirect for one account.
//
// The problem it solves: opening a URL is a plain navigation, so there is no
// Authorization header and the server cannot tell who started it. The app asks for a
// ticket over an authenticated RPC and carries the ticket instead.
type OAuthTicket struct {
	Token     string    `json:"token"`
	UserID    string    `json:"userId"`
	Purpose   string    `json:"purpose"`
	CreatedAt time.Time `json:"createdAt"`
	ExpiresAt time.Time `json:"expiresAt"`
}

// PutOAuthTicket stores a ticket.
func (s *Store) PutOAuthTicket(t *OAuthTicket) error {
	if t == nil || t.Token == "" || t.UserID == "" {
		return ErrInvalidKey
	}
	return s.write(func(tx *sql.Tx) error {
		if _, err := getRow[User](s, tx, "users", t.UserID); err != nil {
			return err
		}
		return s.put(tx, "oauth_tickets", t.Token, t, []string{"owner"}, s.rowID("users", t.UserID))
	})
}

// TakeOAuthTicket reads and deletes a ticket in one step, so it cannot be replayed.
func (s *Store) TakeOAuthTicket(token, purpose string, now time.Time) (*OAuthTicket, error) {
	if token == "" {
		return nil, ErrNotFound
	}
	var out *OAuthTicket
	err := s.write(func(tx *sql.Tx) error {
		t, err := getRow[OAuthTicket](s, tx, "oauth_tickets", token)
		if err != nil {
			return err
		}
		if err := s.remove(tx, "oauth_tickets", token); err != nil {
			return err
		}
		if !t.ExpiresAt.IsZero() && now.After(t.ExpiresAt) {
			return ErrNotFound
		}
		// The purpose is checked after reading, never as a filter: a ticket that was
		// consumed for the wrong purpose must still be gone.
		if purpose != "" && t.Purpose != purpose {
			return ErrNotFound
		}
		out = t
		return nil
	})
	if err != nil {
		return nil, err
	}
	return out, nil
}

// DeleteExpiredOAuthTickets drops tickets nobody used.
func (s *Store) DeleteExpiredOAuthTickets(before time.Time) int {
	removed := 0
	must(s.write(func(tx *sql.Tx) error {
		all, err := listRows[OAuthTicket](s, tx, "oauth_tickets", "")
		if err != nil && err != ErrNotFound {
			return err
		}
		for _, t := range all {
			if t.ExpiresAt.IsZero() || before.After(t.ExpiresAt) {
				if err := s.remove(tx, "oauth_tickets", t.Token); err != nil {
					return err
				}
				removed++
			}
		}
		return nil
	}))
	return removed
}
