package store

import (
	"database/sql"
	"github.com/gokr/ratatosk/server/internal/ids"
	"sort"
	"strings"
	"time"
)

func (s *Store) saveUser(q querier, u *User) error {
	return s.put(q, "users", u.ID, u, []string{"lookup"}, s.digest("username", strings.ToLower(u.Username)))
}
func (s *Store) CreateUser(username, displayName, hash, salt, accent string, now time.Time) (out *User, err error) {
	err = s.write(func(tx *sql.Tx) error {
		var n int
		if e := tx.QueryRow("SELECT count(*) FROM users WHERE lookup=?", s.digest("username", strings.ToLower(username))).Scan(&n); e != nil {
			return e
		}
		if n != 0 {
			return ErrUsernameTaken
		}
		if displayName == "" {
			displayName = username
		}
		out = &User{ID: ids.New("u"), Username: username, DisplayName: displayName, PasswordHash: hash, PasswordSalt: salt, AccentColor: accent, CreatedAt: now, LastSeen: now, LastActive: now}
		return s.saveUser(tx, out)
	})
	if err != nil {
		return nil, err
	}
	return out, nil
}
func (s *Store) UserByID(id string) (*User, error) { return getRow[User](s, s.sql, "users", id) }
func (s *Store) UserByUsername(username string) (*User, error) {
	var id string
	err := s.sql.QueryRow("SELECT id FROM users WHERE lookup=?", s.digest("username", strings.ToLower(strings.TrimSpace(username)))).Scan(&id)
	if err == sql.ErrNoRows {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, err
	}
	return getHash[User](s, s.sql, "users", id)
}
func (s *Store) UpdateUser(id string, fn func(*User)) (out *User, err error) {
	err = s.write(func(tx *sql.Tx) error {
		u, e := getRow[User](s, tx, "users", id)
		if e != nil {
			return e
		}
		fn(u)
		u.ID = id
		var n int
		if e = tx.QueryRow("SELECT count(*) FROM users WHERE lookup=? AND id<>?", s.digest("username", strings.ToLower(u.Username)), s.rowID("users", id)).Scan(&n); e != nil {
			return e
		}
		if n != 0 {
			return ErrUsernameTaken
		}
		out = u
		return s.saveUser(tx, u)
	})
	if err != nil {
		return nil, err
	}
	return out, nil
}
func (s *Store) TouchUser(id string, now time.Time) {
	_, err := s.UpdateUser(id, func(u *User) { u.LastActive = now })
	if err != ErrNotFound {
		must(err)
	}
}
func (s *Store) SetLastSeen(id string, now time.Time) {
	_, err := s.UpdateUser(id, func(u *User) { u.LastSeen = now })
	if err != ErrNotFound {
		must(err)
	}
}
func (s *Store) SearchUsers(excludeID, query string, limit int) []*User {
	all, err := listRows[User](s, s.sql, "users", "")
	must(err)
	if limit <= 0 {
		limit = 20
	}
	q := strings.ToLower(strings.TrimSpace(query))
	out := make([]*User, 0)
	for _, u := range all {
		if u.ID != excludeID && (q == "" || strings.Contains(strings.ToLower(u.Username), q) || strings.Contains(strings.ToLower(u.DisplayName), q)) {
			out = append(out, u)
		}
	}
	sort.Slice(out, func(i, j int) bool {
		if q == "" {
			return out[i].CreatedAt.After(out[j].CreatedAt)
		}
		ei, ej := strings.EqualFold(out[i].Username, q), strings.EqualFold(out[j].Username, q)
		if ei != ej {
			return ei
		}
		return out[i].Username < out[j].Username
	})
	if len(out) > limit {
		out = out[:limit]
	}
	return out
}
func (s *Store) UsersByIDs(ids []string) []*User {
	out := make([]*User, 0, len(ids))
	for _, id := range ids {
		u, e := s.UserByID(id)
		if e == ErrNotFound {
			continue
		}
		must(e)
		out = append(out, u)
	}
	return out
}
func (s *Store) CreateSession(userID string, ttl time.Duration, now time.Time) (out *Session, err error) {
	err = s.write(func(tx *sql.Tx) error {
		if _, e := getRow[User](s, tx, "users", userID); e != nil {
			if e == ErrNotFound {
				return ErrUnknownUser
			}
			return e
		}
		out = &Session{Token: ids.Token(), UserID: userID, CreatedAt: now, ExpiresAt: now.Add(ttl)}
		return s.put(tx, "sessions", out.Token, out, []string{"owner"}, s.rowID("users", userID))
	})
	if err != nil {
		return nil, err
	}
	return out, nil
}
func (s *Store) SessionByToken(token string, now time.Time) (out *Session, err error) {
	expired := false
	err = s.write(func(tx *sql.Tx) error {
		v, e := getRow[Session](s, tx, "sessions", token)
		if e != nil {
			return e
		}
		if !v.ExpiresAt.IsZero() && now.After(v.ExpiresAt) {
			expired = true
			return s.deleteSession(tx, token)
		}
		out = v
		return nil
	})
	if err != nil {
		return nil, err
	}
	if expired {
		return nil, ErrNotFound
	}
	return out, nil
}
func (s *Store) deleteSession(q querier, token string) error {
	if _, e := q.Exec("DELETE FROM push_subscriptions WHERE session=?", s.rowID("sessions", token)); e != nil {
		return e
	}
	return s.remove(q, "sessions", token)
}

// SessionUser resolves a bearer token to its account, for the few plain-HTTP
// handlers that are not behind the Connect interceptor. An expired or unknown token
// is an error, never an anonymous caller: every caller of this needs to know *who*.
func (s *Store) SessionUser(token string, now time.Time) (*User, error) {
	if token == "" {
		return nil, ErrNotFound
	}
	session, err := s.SessionByToken(token, now)
	if err != nil {
		return nil, err
	}
	return s.UserByID(session.UserID)
}

func (s *Store) DeleteSession(token string) {
	must(s.write(func(tx *sql.Tx) error { return s.deleteSession(tx, token) }))
}
func (s *Store) DeleteUserSessions(userID, except string) {
	must(s.write(func(tx *sql.Tx) error {
		all, e := listRows[Session](s, tx, "sessions", "WHERE owner=?", s.rowID("users", userID))
		if e != nil {
			return e
		}
		for _, v := range all {
			if v.Token != except {
				if e = s.deleteSession(tx, v.Token); e != nil {
					return e
				}
			}
		}
		return nil
	}))
}
func (s *Store) CreateInvite(inviterID string, expiresAt time.Time, maxUses, codeLen int, now time.Time) (out *Invite, err error) {
	err = s.write(func(tx *sql.Tx) error {
		if _, e := getRow[User](s, tx, "users", inviterID); e != nil {
			if e == ErrNotFound {
				return ErrUnknownUser
			}
			return e
		}
		if codeLen < 6 {
			codeLen = 10
		}
		for {
			code := ids.Code(codeLen)
			_, e := getRow[Invite](s, tx, "invites", code)
			if e == nil {
				continue
			}
			if e != ErrNotFound {
				return e
			}
			out = &Invite{Code: code, InviterID: inviterID, CreatedAt: now, ExpiresAt: expiresAt, MaxUses: maxUses}
			return s.put(tx, "invites", code, out, []string{"owner"}, s.rowID("users", inviterID))
		}
	})
	if err != nil {
		return nil, err
	}
	return out, nil
}
func (s *Store) InviteByCode(code string) (*Invite, error) {
	return getRow[Invite](s, s.sql, "invites", strings.ToLower(strings.TrimSpace(code)))
}
func (s *Store) ListInvites(userID string) []*Invite {
	out, e := listRows[Invite](s, s.sql, "invites", "WHERE owner=?", s.rowID("users", userID))
	must(e)
	sort.Slice(out, func(i, j int) bool { return out[i].CreatedAt.After(out[j].CreatedAt) })
	return out
}
func (s *Store) UpdateInvite(code string, fn func(*Invite)) (out *Invite, err error) {
	code = strings.ToLower(strings.TrimSpace(code))
	err = s.write(func(tx *sql.Tx) error {
		v, e := getRow[Invite](s, tx, "invites", code)
		if e != nil {
			return e
		}
		fn(v)
		v.Code = code
		out = v
		return s.put(tx, "invites", code, v, []string{"owner"}, s.rowID("users", v.InviterID))
	})
	if err != nil {
		return nil, err
	}
	return out, nil
}

type contactRow struct {
	Owner, Peer string
	Since       time.Time
}

func contactID(a, b string) string { return a + "\x00" + b }
func (s *Store) AddContact(a, b string, now time.Time) error {
	if a == b {
		return nil
	}
	return s.write(func(tx *sql.Tx) error {
		for _, id := range []string{a, b} {
			if _, e := getRow[User](s, tx, "users", id); e != nil {
				if e == ErrNotFound {
					return ErrUnknownUser
				}
				return e
			}
		}
		for _, pair := range [][2]string{{a, b}, {b, a}} {
			id := contactID(pair[0], pair[1])
			_, e := getRow[contactRow](s, tx, "contacts", id)
			if e == nil {
				continue
			}
			if e != ErrNotFound {
				return e
			}
			v := &contactRow{pair[0], pair[1], now}
			if e = s.put(tx, "contacts", id, v, []string{"owner", "peer"}, s.rowID("users", pair[0]), s.rowID("users", pair[1])); e != nil {
				return e
			}
		}
		return nil
	})
}
func (s *Store) RemoveContact(a, b string) {
	must(s.write(func(tx *sql.Tx) error {
		if e := s.remove(tx, "contacts", contactID(a, b)); e != nil {
			return e
		}
		return s.remove(tx, "contacts", contactID(b, a))
	}))
}
func (s *Store) AreContacts(a, b string) bool {
	_, e := getRow[contactRow](s, s.sql, "contacts", contactID(a, b))
	if e == ErrNotFound {
		return false
	}
	must(e)
	return true
}
func (s *Store) ContactsOf(userID string) []ContactEntry {
	all, e := listRows[contactRow](s, s.sql, "contacts", "WHERE owner=?", s.rowID("users", userID))
	must(e)
	out := make([]ContactEntry, 0, len(all))
	for _, v := range all {
		out = append(out, ContactEntry{v.Peer, v.Since})
	}
	return out
}
