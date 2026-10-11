// Package store holds the server's entire state: users, sessions, invites,
// contacts, conversations, messages and attachments.
//
// SQLite transactions persist independent encrypted rows, never a whole-state
// snapshot. Service callbacks operate on copies inside serialized transactions.
package store

import (
	"database/sql"
	"errors"
	"log/slog"
	"os"
	"path/filepath"
	"sync"
	"time"
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
	MaxUses int  `json:"maxUses"`
	Uses    int  `json:"uses"`
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
	ID            string             `json:"id"`
	Kind          string             `json:"kind"`
	Title         string             `json:"title,omitempty"`
	Avatar        string             `json:"avatar,omitempty"` // attachment id
	CreatedBy     string             `json:"createdBy"`
	CreatedAt     time.Time          `json:"createdAt"`
	UpdatedAt     time.Time          `json:"updatedAt"`
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

// Store owns a SQLite connection pool. Payloads are encrypted; equality indexes
// are keyed digests. The mutex serializes compound operations and callbacks.
type Store struct {
	dir          string
	log          *slog.Logger
	mu           sync.RWMutex
	sql          *sql.DB
	closeOnce    sync.Once
	closeErr     error
	keyOnce      sync.Once
	dataKeyValue []byte
	keyErr       error
}

const snapshotName = "ratatosk.json"
const databaseName = "ratatosk.db"

func Open(dir string, log *slog.Logger) (*Store, error) {
	if log == nil {
		log = slog.Default()
	}
	if err := os.MkdirAll(filepath.Join(dir, "files"), 0700); err != nil {
		return nil, err
	}
	s := &Store{dir: dir, log: log}
	if err := s.openSQLite(); err != nil {
		if s.sql != nil {
			s.sql.Close()
		}
		return nil, err
	}
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

// Dir returns the data directory.
func (s *Store) Dir() string                     { return s.dir }
func (s *Store) FilesDir() string                { return filepath.Join(s.dir, "files") }
func (s *Store) AttachmentPath(id string) string { return filepath.Join(s.FilesDir(), id) }

// Flush is a compatibility barrier: every mutation is already committed with
// SQLite synchronous=FULL before returning. No background snapshot is written.
func (s *Store) Flush() error { return s.sql.Ping() }
func (s *Store) Close() error {
	s.closeOnce.Do(func() { s.closeErr = s.sql.Close() })
	return s.closeErr
}

// View materializes an isolated, consistent compatibility view. It is not the
// persistence model; normal reads and writes query individual indexed rows.
func (s *Store) View(fn func(db *DB) error) error {
	s.mu.RLock()
	defer s.mu.RUnlock()
	tx, err := s.sql.Begin()
	if err != nil {
		return err
	}
	defer tx.Rollback()
	db, err := s.readLegacyView(tx)
	if err != nil {
		return err
	}
	return fn(db)
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
	var out Stats
	for table, n := range map[string]*int{"users": &out.Users, "conversations": &out.Conversations, "messages": &out.Messages, "invites": &out.Invites} {
		must(s.sql.QueryRow("SELECT count(*) FROM " + table).Scan(n))
	}
	return out
}
