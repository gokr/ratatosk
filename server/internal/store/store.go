// Package store holds the server's entire state: users, sessions, invites,
// contacts, conversations, messages and attachments.
//
// Design notes
//
//   - The whole database is in memory and persisted as one JSON document
//     written atomically (temp file + rename), debounced by a short interval,
//     plus a forced write on shutdown. That keeps the server a single
//     dependency-free binary and makes tests trivial. It is deliberately not a
//     SQL database: if this ever needs to hold more than one process' worth of
//     traffic, replace this package's bodies with SQL behind the same methods
//     instead of spreading queries through the service layer.
//   - One RWMutex guards everything. Reads return deep copies so callers never
//     observe a struct while another goroutine mutates it; mutations happen
//     inside the store through small update functions that run under the write
//     lock. Those functions must not call back into the store (deadlock).
//   - Messages are never deleted, only tombstoned, so a conversation's message
//     list stays gapless and index i always corresponds to seq i+1. Every
//     pagination and catch-up path relies on that invariant.
package store

import (
	"encoding/json"
	"errors"
	"fmt"
	"log/slog"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"sync"
	"time"

	"github.com/gokr/ratatosk/server/internal/ids"
)

// Sentinel errors returned by the store. The service layer maps them onto
// Connect status codes; the store itself knows nothing about the wire.
var (
	ErrNotFound       = errors.New("store: not found")
	ErrUsernameTaken  = errors.New("store: username already taken")
	ErrAlreadyExists  = errors.New("store: already exists")
	ErrUnknownUser    = errors.New("store: unknown user")
	ErrNotMember      = errors.New("store: not a member")
	ErrInvalidMessage = errors.New("store: invalid message")
)

// dbVersion is bumped when the on-disk shape changes in a way that needs
// migration. A snapshot with a newer version is refused rather than truncated.
const dbVersion = 1

// Conversation kinds.
const (
	KindDirect = "direct"
	KindGroup  = "group"
)

// Member roles.
const (
	RoleOwner  = "owner"
	RoleMember = "member"
)

// Message kinds.
const (
	MessageText   = "text"
	MessageSystem = "system"
)

// User is an account. Credentials never leave the store.
type User struct {
	ID           string    `json:"id"`
	Username     string    `json:"username"`
	DisplayName  string    `json:"displayName"`
	Bio          string    `json:"bio,omitempty"`
	Avatar       string    `json:"avatar,omitempty"` // attachment id
	AccentColor  string    `json:"accentColor"`
	PasswordHash string    `json:"passwordHash"`
	PasswordSalt string    `json:"passwordSalt"`
	CreatedAt    time.Time `json:"createdAt"`
	// LastSeen is when the user was last connected; LastActive is the last
	// authenticated request, used to tell "online" from "away".
	LastSeen   time.Time `json:"lastSeen"`
	LastActive time.Time `json:"lastActive"`
}

// Session is one logged-in client.
type Session struct {
	Token     string    `json:"token"`
	UserID    string    `json:"userId"`
	CreatedAt time.Time `json:"createdAt"`
	ExpiresAt time.Time `json:"expiresAt"`
}

// Invite is a shareable link that makes two accounts contacts when redeemed.
type Invite struct {
	Code      string    `json:"code"`
	InviterID string    `json:"inviterId"`
	CreatedAt time.Time `json:"createdAt"`
	// Zero means the invite never expires.
	ExpiresAt time.Time `json:"expiresAt,omitempty"`
	// Zero means unlimited uses.
	MaxUses int `json:"maxUses"`
	Uses    int `json:"uses"`
	Revoked bool `json:"revoked"`
	// RedeemedBy lists user ids, newest first.
	RedeemedBy []string `json:"redeemedBy,omitempty"`
}

// ContactEntry is one row of a user's contact list.
type ContactEntry struct {
	UserID string
	Since  time.Time
}

// Member is one participant of a conversation.
type Member struct {
	UserID      string    `json:"userId"`
	Role        string    `json:"role"`
	JoinedAt    time.Time `json:"joinedAt"`
	LastReadSeq int64     `json:"lastReadSeq"`
	LastReadAt  time.Time `json:"lastReadAt"`
	Muted       bool      `json:"muted,omitempty"`
	Pinned      bool      `json:"pinned,omitempty"`
}

// Conversation is a direct or group chat. Members and messages are what give
// it meaning; everything else is presentation state.
type Conversation struct {
	ID               string             `json:"id"`
	Kind             string             `json:"kind"`
	Title            string             `json:"title,omitempty"`
	Avatar           string             `json:"avatar,omitempty"` // attachment id
	CreatedBy        string             `json:"createdBy"`
	CreatedAt        time.Time          `json:"createdAt"`
	UpdatedAt        time.Time          `json:"updatedAt"`
	LastSeq       int64              `json:"lastSeq"`
	LastMessageID string             `json:"lastMessageId,omitempty"`
	Members       map[string]*Member `json:"members"`
}

// Message is one chat message. Deleted messages keep their row and seq.
type Message struct {
	ID              string              `json:"id"`
	ConversationID  string              `json:"conversationId"`
	SenderID        string              `json:"senderId"`
	Kind            string              `json:"kind"`
	Text            string              `json:"text,omitempty"`
	Attachments     []string            `json:"attachments,omitempty"` // attachment ids
	CreatedAt       time.Time           `json:"createdAt"`
	EditedAt        time.Time           `json:"editedAt,omitempty"`
	Deleted         bool                `json:"deleted,omitempty"`
	ReplyToID       string              `json:"replyToId,omitempty"`
	ClientMessageID string              `json:"clientMessageId,omitempty"`
	Reactions       map[string][]string `json:"reactions,omitempty"` // emoji -> user ids
	Seq             int64               `json:"seq"`

	// End-to-end encryption (docs/E2EE.md). The server stores these without
	// ever holding a key that opens them.
	Ciphertext        []byte `json:"ciphertext,omitempty"`
	Nonce             []byte `json:"nonce,omitempty"`
	SenderDeviceKeyID string `json:"senderDeviceKeyId,omitempty"`
	KeyEpoch          int32  `json:"keyEpoch,omitempty"`
	CryptoVersion     string `json:"cryptoVersion,omitempty"`
}

// Encrypted reports whether the message body is a client-side seal.
func (m *Message) Encrypted() bool { return len(m.Ciphertext) > 0 }

// Attachment is an uploaded file; the bytes live on disk under FilesDir.
type Attachment struct {
	ID          string    `json:"id"`
	OwnerID     string    `json:"ownerId"`
	Filename    string    `json:"filename"`
	ContentType string    `json:"contentType"`
	Size        int64     `json:"size"`
	Width       int       `json:"width,omitempty"`
	Height      int       `json:"height,omitempty"`
	CreatedAt   time.Time `json:"createdAt"`
	// The stored bytes are a client-side seal, so the name and type above are
	// intentionally empty and the server knows nothing about the content.
	Encrypted bool `json:"encrypted,omitempty"`
}

// DB is the serialized form of the whole store.
type DB struct {
	Version       int                             `json:"version"`
	Users         map[string]*User                `json:"users"`
	Sessions      map[string]*Session             `json:"sessions"`
	Invites       map[string]*Invite              `json:"invites"`
	Contacts      map[string]map[string]time.Time `json:"contacts"`
	Conversations map[string]*Conversation        `json:"conversations"`
	Messages      map[string]*Message             `json:"messages"`
	ConvMessages  map[string][]string             `json:"convMessages"`
	Attachments   map[string]*Attachment          `json:"attachments"`
	// Public encryption keys and the sealed sender keys addressed to devices.
	// Both are safe to store: the server cannot read either.
	DeviceKeys   map[string]*DeviceKey   `json:"deviceKeys"`
	KeyEnvelopes map[string]*KeyEnvelope `json:"keyEnvelopes"`
}

// Store is the concurrency-safe façade over DB plus its persistence.
type Store struct {
	dir  string
	log  *slog.Logger
	mu sync.RWMutex
	db *DB
	// usernames indexes lowercased handles to user ids for login and lookup.
	usernames map[string]string
	// clientIndex maps a sender's idempotency key to a message id, so a
	// retried send returns the original message instead of duplicating it.
	// Derived state: rebuilt from Messages on load, never persisted.
	clientIndex map[string]string
	dirty      bool
	flushEvery time.Duration
	stop       chan struct{}
	done       chan struct{}
	closeOnce  sync.Once

	// The key that seals the snapshot, loaded once on first use.
	keyOnce      sync.Once
	dataKeyValue []byte
	keyErr       error
}

const snapshotName = "ratatosk.json"

// Open loads (or initializes) the store rooted at dir, creating dir and its
// files/ subdirectory, and starts the background snapshot writer.
func Open(dir string, log *slog.Logger) (*Store, error) {
	if log == nil {
		log = slog.Default()
	}
	if err := os.MkdirAll(filepath.Join(dir, "files"), 0o755); err != nil {
		return nil, fmt.Errorf("store: create data dir: %w", err)
	}
	s := &Store{
		dir:         dir,
		log:         log,
		db:          newDB(),
		usernames:   map[string]string{},
		clientIndex: map[string]string{},
		flushEvery:  500 * time.Millisecond,
		stop:       make(chan struct{}),
		done:       make(chan struct{}),
	}
	if err := s.load(); err != nil {
		return nil, err
	}
	go s.flushLoop()
	return s, nil
}

func newDB() *DB {
	return &DB{
		Version:       dbVersion,
		Users:         map[string]*User{},
		Sessions:      map[string]*Session{},
		Invites:       map[string]*Invite{},
		Contacts:      map[string]map[string]time.Time{},
		Conversations: map[string]*Conversation{},
		Messages:      map[string]*Message{},
		ConvMessages:  map[string][]string{},
		Attachments:   map[string]*Attachment{},
		DeviceKeys:    map[string]*DeviceKey{},
		KeyEnvelopes:  map[string]*KeyEnvelope{},
	}
}

func (s *Store) load() error {
	path := filepath.Join(s.dir, snapshotName)
	raw, err := os.ReadFile(path)
	if errors.Is(err, os.ErrNotExist) {
		return nil // fresh store
	}
	if err != nil {
		return fmt.Errorf("store: read snapshot: %w", err)
	}
	plain, err := s.unsealSnapshot(raw)
	if err != nil {
		return fmt.Errorf("store: read %s: %w", path, err)
	}
	var db DB
	if err := json.Unmarshal(plain, &db); err != nil {
		return fmt.Errorf("store: parse %s: %w", path, err)
	}
	if db.Version > dbVersion {
		return fmt.Errorf("store: %s was written by a newer server (version %d > %d)", path, db.Version, dbVersion)
	}
	// Unmarshal leaves nil maps for absent keys; fill them so handlers never
	// have to distinguish "empty" from "missing".
	if db.Users == nil { db.Users = map[string]*User{} }
	if db.Sessions == nil { db.Sessions = map[string]*Session{} }
	if db.Invites == nil { db.Invites = map[string]*Invite{} }
	if db.Contacts == nil { db.Contacts = map[string]map[string]time.Time{} }
	if db.Conversations == nil { db.Conversations = map[string]*Conversation{} }
	if db.Messages == nil { db.Messages = map[string]*Message{} }
	if db.ConvMessages == nil { db.ConvMessages = map[string][]string{} }
	if db.Attachments == nil { db.Attachments = map[string]*Attachment{} }
	if db.DeviceKeys == nil { db.DeviceKeys = map[string]*DeviceKey{} }
	if db.KeyEnvelopes == nil { db.KeyEnvelopes = map[string]*KeyEnvelope{} }
	db.Version = dbVersion
	for _, c := range db.Conversations {
		if c.Members == nil {
			c.Members = map[string]*Member{}
		}
	}
	s.db = &db
	for id, u := range db.Users {
		u.ID = id
		s.usernames[strings.ToLower(u.Username)] = id
	}
	for _, m := range db.Messages {
		if m.ClientMessageID != "" {
			s.clientIndex[clientKey(m.ConversationID, m.SenderID, m.ClientMessageID)] = m.ID
		}
	}
	s.log.Info("store loaded", "users", len(db.Users), "conversations", len(db.Conversations), "messages", len(db.Messages))
	return nil
}

// Dir returns the data directory.
func (s *Store) Dir() string { return s.dir }

// FilesDir is where attachment bytes are stored.
func (s *Store) FilesDir() string { return filepath.Join(s.dir, "files") }

// AttachmentPath is the on-disk path of an attachment's bytes.
func (s *Store) AttachmentPath(id string) string { return filepath.Join(s.FilesDir(), id) }

func (s *Store) flushLoop() {
	defer close(s.done)
	t := time.NewTicker(s.flushEvery)
	defer t.Stop()
	for {
		select {
		case <-s.stop:
			return
		case <-t.C:
			if err := s.Flush(); err != nil {
				s.log.Error("store snapshot failed", "err", err)
			}
		}
	}
}

// Flush writes the current state to disk if anything changed.
func (s *Store) Flush() error {
	s.mu.Lock()
	if !s.dirty {
		s.mu.Unlock()
		return nil
	}
	s.dirty = false
	plain, err := json.Marshal(s.db)
	s.mu.Unlock()
	if err != nil {
		return fmt.Errorf("store: encode snapshot: %w", err)
	}
	// Everything the server holds is sealed before it touches the disk; the
	// key lives outside the database (see atrest.go).
	raw, err := s.sealSnapshot(plain)
	if err != nil {
		return err
	}
	tmp := filepath.Join(s.dir, snapshotName+".tmp")
	if err := os.WriteFile(tmp, raw, 0o600); err != nil {
		return fmt.Errorf("store: write snapshot: %w", err)
	}
	if err := os.Rename(tmp, filepath.Join(s.dir, snapshotName)); err != nil {
		return fmt.Errorf("store: commit snapshot: %w", err)
	}
	return nil
}

// Close stops the snapshot writer and performs a final flush.
func (s *Store) Close() error {
	var err error
	s.closeOnce.Do(func() {
		close(s.stop)
		<-s.done
		err = s.Flush()
	})
	return err
}

// markDirty must be called with the write lock held.
func (s *Store) markDirty() { s.dirty = true }

// View runs fn with read access to the store's maps. It exists for the few
// read paths that need to touch several maps consistently; fn must not call
// other store methods, and anything it returns must be a copy.
func (s *Store) View(fn func(db *DB) error) error {
	s.mu.RLock()
	defer s.mu.RUnlock()
	return fn(s.db)
}

// --- users ---------------------------------------------------------------

// CreateUser registers an account. The caller is responsible for hashing.
func (s *Store) CreateUser(username, displayName, hash, salt, accent string, now time.Time) (*User, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	key := strings.ToLower(username)
	if _, ok := s.usernames[key]; ok {
		return nil, ErrUsernameTaken
	}
	if displayName == "" {
		displayName = username
	}
	u := &User{
		ID:           ids.New("u"),
		Username:     username,
		DisplayName:  displayName,
		AccentColor:  accent,
		PasswordHash: hash,
		PasswordSalt: salt,
		CreatedAt:    now,
		LastSeen:     now,
		LastActive:   now,
	}
	s.db.Users[u.ID] = u
	s.usernames[key] = u.ID
	s.markDirty()
	return cloneUser(u), nil
}

// UserByID returns a copy of the user, or ErrNotFound.
func (s *Store) UserByID(id string) (*User, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	u, ok := s.db.Users[id]
	if !ok {
		return nil, ErrNotFound
	}
	return cloneUser(u), nil
}

// UserByUsername resolves a handle case-insensitively.
func (s *Store) UserByUsername(username string) (*User, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	id, ok := s.usernames[strings.ToLower(strings.TrimSpace(username))]
	if !ok {
		return nil, ErrNotFound
	}
	u, ok := s.db.Users[id]
	if !ok {
		return nil, ErrNotFound
	}
	return cloneUser(u), nil
}

// UpdateUser applies fn to the stored user under the write lock and returns a
// copy of the result. fn must not call other store methods.
func (s *Store) UpdateUser(id string, fn func(*User)) (*User, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	u, ok := s.db.Users[id]
	if !ok {
		return nil, ErrNotFound
	}
	before := u.Username
	fn(u)
	if !strings.EqualFold(before, u.Username) {
		delete(s.usernames, strings.ToLower(before))
		s.usernames[strings.ToLower(u.Username)] = u.ID
	}
	s.markDirty()
	return cloneUser(u), nil
}

// TouchUser records activity, which drives presence ("online" vs "away").
func (s *Store) TouchUser(id string, now time.Time) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if u, ok := s.db.Users[id]; ok {
		u.LastActive = now
		s.markDirty()
	}
}

// SetLastSeen records the last moment a user was connected.
func (s *Store) SetLastSeen(id string, at time.Time) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if u, ok := s.db.Users[id]; ok {
		u.LastSeen = at
		s.markDirty()
	}
}

// SearchUsers finds accounts by handle or display name. An empty query lists
// the most recently created accounts, so a fresh install has people to find.
func (s *Store) SearchUsers(excludeID, query string, limit int) []*User {
	s.mu.RLock()
	defer s.mu.RUnlock()
	if limit <= 0 {
		limit = 20
	}
	q := strings.ToLower(strings.TrimSpace(query))
	var out []*User
	for _, u := range s.db.Users {
		if u.ID == excludeID {
			continue
		}
		if q != "" && !strings.Contains(strings.ToLower(u.Username), q) &&
			!strings.Contains(strings.ToLower(u.DisplayName), q) {
			continue
		}
		out = append(out, cloneUser(u))
	}
	sort.Slice(out, func(i, j int) bool {
		if q == "" {
			return out[i].CreatedAt.After(out[j].CreatedAt)
		}
		// Exact handle matches first, then by handle for stability.
		ei := strings.EqualFold(out[i].Username, q)
		ej := strings.EqualFold(out[j].Username, q)
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

// UsersByIDs returns copies of the named users, skipping unknown ids.
func (s *Store) UsersByIDs(userIDs []string) []*User {
	s.mu.RLock()
	defer s.mu.RUnlock()
	out := make([]*User, 0, len(userIDs))
	for _, id := range userIDs {
		if u, ok := s.db.Users[id]; ok {
			out = append(out, cloneUser(u))
		}
	}
	return out
}

// --- sessions ------------------------------------------------------------

// CreateSession issues a token for a user.
func (s *Store) CreateSession(userID string, ttl time.Duration, now time.Time) (*Session, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if _, ok := s.db.Users[userID]; !ok {
		return nil, ErrUnknownUser
	}
	sess := &Session{
		Token:     ids.Token(),
		UserID:    userID,
		CreatedAt: now,
		ExpiresAt: now.Add(ttl),
	}
	s.db.Sessions[sess.Token] = sess
	s.markDirty()
	return cloneSession(sess), nil
}

// SessionByToken resolves a token, dropping it when expired.
func (s *Store) SessionByToken(token string, now time.Time) (*Session, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	sess, ok := s.db.Sessions[token]
	if !ok {
		return nil, ErrNotFound
	}
	if !sess.ExpiresAt.IsZero() && now.After(sess.ExpiresAt) {
		delete(s.db.Sessions, token)
		s.markDirty()
		return nil, ErrNotFound
	}
	return cloneSession(sess), nil
}

// DeleteSession revokes one token.
func (s *Store) DeleteSession(token string) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if _, ok := s.db.Sessions[token]; ok {
		delete(s.db.Sessions, token)
		s.markDirty()
	}
}

// DeleteUserSessions revokes every token of a user except the given one
// (pass "" to revoke all), used after a password change.
func (s *Store) DeleteUserSessions(userID, except string) {
	s.mu.Lock()
	defer s.mu.Unlock()
	for tok, sess := range s.db.Sessions {
		if sess.UserID == userID && tok != except {
			delete(s.db.Sessions, tok)
		}
	}
	s.markDirty()
}

// --- invites -------------------------------------------------------------

// CreateInvite stores a new invite. The code is generated here so callers
// cannot pick a guessable one.
func (s *Store) CreateInvite(inviterID string, expiresAt time.Time, maxUses int, codeLen int, now time.Time) (*Invite, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if _, ok := s.db.Users[inviterID]; !ok {
		return nil, ErrUnknownUser
	}
	if codeLen < 6 {
		codeLen = 10
	}
	for {
		code := ids.Code(codeLen)
		if _, exists := s.db.Invites[code]; exists {
			continue
		}
		inv := &Invite{
			Code:      code,
			InviterID: inviterID,
			CreatedAt: now,
			ExpiresAt: expiresAt,
			MaxUses:   maxUses,
		}
		s.db.Invites[code] = inv
		s.markDirty()
		return cloneInvite(inv), nil
	}
}

// InviteByCode looks up an invite; the code is case-insensitive because
// people retype invite links by hand.
func (s *Store) InviteByCode(code string) (*Invite, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	inv, ok := s.db.Invites[strings.ToLower(strings.TrimSpace(code))]
	if !ok {
		return nil, ErrNotFound
	}
	return cloneInvite(inv), nil
}

// ListInvites returns the invites created by a user, newest first.
func (s *Store) ListInvites(inviterID string) []*Invite {
	s.mu.RLock()
	defer s.mu.RUnlock()
	var out []*Invite
	for _, inv := range s.db.Invites {
		if inv.InviterID == inviterID {
			out = append(out, cloneInvite(inv))
		}
	}
	sort.Slice(out, func(i, j int) bool { return out[i].CreatedAt.After(out[j].CreatedAt) })
	return out
}

// UpdateInvite applies fn to the stored invite under the write lock.
func (s *Store) UpdateInvite(code string, fn func(*Invite)) (*Invite, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	inv, ok := s.db.Invites[strings.ToLower(strings.TrimSpace(code))]
	if !ok {
		return nil, ErrNotFound
	}
	fn(inv)
	s.markDirty()
	return cloneInvite(inv), nil
}

// --- contacts ------------------------------------------------------------

// AddContact links two users in both directions (contacts are symmetric).
func (s *Store) AddContact(a, b string, now time.Time) error {
	if a == b {
		return nil
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	if _, ok := s.db.Users[a]; !ok {
		return ErrUnknownUser
	}
	if _, ok := s.db.Users[b]; !ok {
		return ErrUnknownUser
	}
	for _, pair := range [][2]string{{a, b}, {b, a}} {
		if s.db.Contacts[pair[0]] == nil {
			s.db.Contacts[pair[0]] = map[string]time.Time{}
		}
		if _, ok := s.db.Contacts[pair[0]][pair[1]]; !ok {
			s.db.Contacts[pair[0]][pair[1]] = now
		}
	}
	s.markDirty()
	return nil
}

// RemoveContact drops a contact link in both directions.
func (s *Store) RemoveContact(a, b string) {
	s.mu.Lock()
	defer s.mu.Unlock()
	for _, pair := range [][2]string{{a, b}, {b, a}} {
		if m := s.db.Contacts[pair[0]]; m != nil {
			delete(m, pair[1])
		}
	}
	s.markDirty()
}

// AreContacts reports whether two users are contacts.
func (s *Store) AreContacts(a, b string) bool {
	s.mu.RLock()
	defer s.mu.RUnlock()
	if s.db.Contacts[a] == nil {
		return false
	}
	_, ok := s.db.Contacts[a][b]
	return ok
}

// ContactsOf lists a user's contacts as (id, since) pairs.
func (s *Store) ContactsOf(userID string) []ContactEntry {
	s.mu.RLock()
	defer s.mu.RUnlock()
	out := make([]ContactEntry, 0, len(s.db.Contacts[userID]))
	for id, since := range s.db.Contacts[userID] {
		out = append(out, ContactEntry{UserID: id, Since: since})
	}
	return out
}

// --- cloning -------------------------------------------------------------
//
// Everything handed to callers is a copy: the store mutates its own structs
// under the write lock, so a shared pointer would be a data race waiting to
// happen.

func cloneUser(u *User) *User {
	c := *u
	return &c
}

func cloneSession(s *Session) *Session {
	c := *s
	return &c
}

func cloneInvite(i *Invite) *Invite {
	c := *i
	c.RedeemedBy = append([]string(nil), i.RedeemedBy...)
	return &c
}

func cloneMember(m *Member) *Member {
	c := *m
	return &c
}

func cloneConversation(c *Conversation) *Conversation {
	out := *c
	out.Members = make(map[string]*Member, len(c.Members))
	for id, m := range c.Members {
		out.Members[id] = cloneMember(m)
	}
	return &out
}

func cloneMessage(m *Message) *Message {
	out := *m
	out.Attachments = append([]string(nil), m.Attachments...)
	out.Ciphertext = append([]byte(nil), m.Ciphertext...)
	out.Nonce = append([]byte(nil), m.Nonce...)
	if m.Reactions != nil {
		out.Reactions = make(map[string][]string, len(m.Reactions))
		for emoji, users := range m.Reactions {
			out.Reactions[emoji] = append([]string(nil), users...)
		}
	}
	return &out
}

func cloneAttachment(a *Attachment) *Attachment {
	c := *a
	return &c
}

// Stats is a small read-only summary used by the landing page and logs.
type Stats struct {
	Users         int
	Conversations int
	Messages      int
	Invites       int
}

// Stats returns live counters.
func (s *Store) Stats() Stats {
	s.mu.RLock()
	defer s.mu.RUnlock()
	return Stats{
		Users:         len(s.db.Users),
		Conversations: len(s.db.Conversations),
		Messages:      len(s.db.Messages),
		Invites:       len(s.db.Invites),
	}
}
