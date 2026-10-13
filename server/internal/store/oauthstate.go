package store

import (
	"database/sql"
	"time"
)

// OAuthState is a one-time value binding a browser to the consent redirect it
// started, so a callback cannot be forged or replayed.
type OAuthState struct {
	State        string    `json:"state"`
	CodeVerifier string    `json:"codeVerifier"`
	RedirectURI  string    `json:"redirectUri"`
	CreatedAt    time.Time `json:"createdAt"`
	ExpiresAt    time.Time `json:"expiresAt"`
}

// PutOAuthState stores a pending sign-in attempt.
//
// Held server-side rather than in a signed cookie so PKCE's verifier never has to
// travel through the browser at all: the only thing the browser carries is the
// opaque state string, which is useless without the row.
func (s *Store) PutOAuthState(st *OAuthState) error {
	if st == nil || st.State == "" || st.CodeVerifier == "" {
		return ErrInvalidKey
	}
	return s.write(func(tx *sql.Tx) error {
		return s.put(tx, "oauth_states", st.State, st, []string{})
	})
}

// TakeOAuthState reads and deletes a pending sign-in attempt in one step.
//
// Deleting on read is what makes the state single-use: a replayed callback finds
// nothing, so a link captured from history or a log cannot be redeemed twice.
func (s *Store) TakeOAuthState(state string, now time.Time) (*OAuthState, error) {
	if state == "" {
		return nil, ErrNotFound
	}
	var out *OAuthState
	err := s.write(func(tx *sql.Tx) error {
		st, err := getRow[OAuthState](s, tx, "oauth_states", state)
		if err != nil {
			return err
		}
		if err := s.remove(tx, "oauth_states", state); err != nil {
			return err
		}
		if !st.ExpiresAt.IsZero() && now.After(st.ExpiresAt) {
			return ErrNotFound
		}
		out = st
		return nil
	})
	if err != nil {
		return nil, err
	}
	return out, nil
}

// DeleteExpiredOAuthStates keeps the table from growing without bound. A pending
// sign-in lives for minutes, so anything older is abandoned.
func (s *Store) DeleteExpiredOAuthStates(before time.Time) int {
	removed := 0
	must(s.write(func(tx *sql.Tx) error {
		all, err := listRows[OAuthState](s, tx, "oauth_states", "")
		if err != nil && err != ErrNotFound {
			return err
		}
		for _, st := range all {
			if st.ExpiresAt.IsZero() || before.After(st.ExpiresAt) {
				if err := s.remove(tx, "oauth_states", st.State); err != nil {
					return err
				}
				removed++
			}
		}
		return nil
	}))
	return removed
}
