package store

import (
	"database/sql"
	"strings"
	"time"
)

// OAuthIdentity links an external sign-in (Google) to a local account.
//
// The link is by the provider's immutable `sub` claim, never by email address:
// email can be changed on the provider's side, and a matching address is not proof
// of the same person. That is the whole account-takeover risk in social login, and
// using `sub` is what avoids it.
type OAuthIdentity struct {
	UserID        string    `json:"userId"`
	Provider      string    `json:"provider"`
	Subject       string    `json:"subject"`
	Email         string    `json:"email"`
	EmailVerified bool      `json:"emailVerified"`
	Name          string    `json:"name"`
	CreatedAt     time.Time `json:"createdAt"`
	LastLogin     time.Time `json:"lastLogin"`
}

// oauthRowID is the primary key: one row per (provider, subject) pair.
func oauthRowID(provider, subject string) string {
	return strings.ToLower(provider) + "\x00" + subject
}

func normalizeProvider(provider string) string {
	return strings.ToLower(strings.TrimSpace(provider))
}

// PutOAuthIdentity records a sign-in link, or refreshes an existing one.
//
// The account is never changed by this: a link that already exists keeps its
// UserID, so a provider's email change or a name change cannot move the identity to
// a different account. CreatedAt is preserved across refreshes for the same reason.
func (s *Store) PutOAuthIdentity(id *OAuthIdentity) error {
	if id == nil || id.UserID == "" || id.Provider == "" || id.Subject == "" {
		return ErrInvalidKey
	}
	provider := normalizeProvider(id.Provider)
	return s.write(func(tx *sql.Tx) error {
		if _, err := getRow[User](s, tx, "users", id.UserID); err != nil {
			return err
		}
		copy := *id
		copy.Provider = provider
		rowID := oauthRowID(provider, id.Subject)
		existing, err := getRow[OAuthIdentity](s, tx, "oauth_identities", rowID)
		switch {
		case err == nil:
			// A link already pointing at a different account is refused rather
			// than re-pointed: the alternative is that signing in with somebody
			// else's provider identity could seize an existing account.
			if existing.UserID != id.UserID {
				return ErrAlreadyExists
			}
			copy.CreatedAt = existing.CreatedAt
		case err == ErrNotFound:
			if copy.CreatedAt.IsZero() {
				copy.CreatedAt = time.Now()
			}
		default:
			return err
		}
		if copy.LastLogin.IsZero() {
			copy.LastLogin = time.Now()
		}
		return s.put(tx, "oauth_identities", rowID, &copy,
			[]string{"owner", "provider", "subject"},
			s.rowID("users", copy.UserID), provider, id.Subject)
	})
}

// OAuthIdentityBySubject finds the account a provider identity is linked to.
func (s *Store) OAuthIdentityBySubject(provider, subject string) (*OAuthIdentity, error) {
	return getRow[OAuthIdentity](s, s.sql, "oauth_identities", oauthRowID(provider, subject))
}

// DeleteOAuthIdentity removes a provider link from an account. An unknown provider is
// not an error: the caller asked for the link to be gone, and it is.
func (s *Store) DeleteOAuthIdentity(userID, provider string) error {
	links := s.OAuthIdentitiesOf(userID)
	provider = normalizeProvider(provider)
	for _, link := range links {
		if link.Provider != provider {
			continue
		}
		if err := s.write(func(tx *sql.Tx) error {
			return s.remove(tx, "oauth_identities", oauthRowID(link.Provider, link.Subject))
		}); err != nil {
			return err
		}
	}
	return nil
}

// OAuthIdentitiesOf lists the sign-in methods an account has.
func (s *Store) OAuthIdentitiesOf(userID string) []*OAuthIdentity {
	out, err := listRows[OAuthIdentity](s, s.sql, "oauth_identities", "WHERE owner=?", s.rowID("users", userID))
	if err == ErrNotFound {
		return nil
	}
	must(err)
	return out
}
