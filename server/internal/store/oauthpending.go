package store

import (
	"database/sql"
	"time"
)

// OAuthPending is a verified external identity that has not become an account yet.
//
// It exists because the two halves of "sign in with Google" happen at different
// times: the provider confirms who somebody is during the redirect, but the account
// is only created once they have proved an invitation and chosen a username. Rather
// than trusting the browser to hand the verified identity back, it is kept here and
// referenced by an opaque one-time token.
//
// The identity is already verified at this point, so the token is the only thing
// protecting it: it is random, single-use, short-lived, and never leaves the server
// except to the browser that just came back from the provider.
type OAuthPending struct {
	Token      string    `json:"token"`
	Provider   string    `json:"provider"`
	Subject    string    `json:"subject"`
	Email      string    `json:"email"`
	Name       string    `json:"name"`
	InviteCode string    `json:"inviteCode"`
	CreatedAt  time.Time `json:"createdAt"`
	ExpiresAt  time.Time `json:"expiresAt"`
}

// PutOAuthPending stores a verified identity awaiting a username and an invitation.
func (s *Store) PutOAuthPending(p *OAuthPending) error {
	if p == nil || p.Token == "" || p.Provider == "" || p.Subject == "" {
		return ErrInvalidKey
	}
	return s.write(func(tx *sql.Tx) error {
		return s.put(tx, "oauth_pending", p.Token, p, []string{})
	})
}

// TakeOAuthPending reads and deletes a pending identity in one step.
//
// Deleting on read is what stops a token from being replayed into several accounts:
// the second attempt finds nothing. It also means an abandoned attempt leaves no
// trace, which is the right default for something holding a verified identity.
func (s *Store) TakeOAuthPending(token string, now time.Time) (*OAuthPending, error) {
	if token == "" {
		return nil, ErrNotFound
	}
	var out *OAuthPending
	err := s.write(func(tx *sql.Tx) error {
		p, err := getRow[OAuthPending](s, tx, "oauth_pending", token)
		if err != nil {
			return err
		}
		if err := s.remove(tx, "oauth_pending", token); err != nil {
			return err
		}
		if !p.ExpiresAt.IsZero() && now.After(p.ExpiresAt) {
			return ErrNotFound
		}
		out = p
		return nil
	})
	if err != nil {
		return nil, err
	}
	return out, nil
}

// DeleteExpiredOAuthPending drops abandoned attempts.
func (s *Store) DeleteExpiredOAuthPending(before time.Time) int {
	removed := 0
	must(s.write(func(tx *sql.Tx) error {
		all, err := listRows[OAuthPending](s, tx, "oauth_pending", "")
		if err != nil && err != ErrNotFound {
			return err
		}
		for _, p := range all {
			if p.ExpiresAt.IsZero() || before.After(p.ExpiresAt) {
				if err := s.remove(tx, "oauth_pending", p.Token); err != nil {
					return err
				}
				removed++
			}
		}
		return nil
	}))
	return removed
}

// DisableUserPassword clears an account's password, leaving it reachable only
// through a linked sign-in.
//
// Deliberately not exposed as an RPC: nothing in the product should be able to take
// away the password of an account that relies on it. It exists for the one case
// where it is correct — an account created *through* Google, which never had one.
func (s *Store) SetUserPassword(userID, hash, salt string) error {
	_, err := s.UpdateUser(userID, func(u *User) {
		u.PasswordHash = hash
		u.PasswordSalt = salt
	})
	return err
}
