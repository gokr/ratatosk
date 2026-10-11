package store

import (
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"io/fs"
	"net/url"
	"os"
	"path/filepath"
	"strings"
	"time"
)

// rowTables lists every table that holds one encrypted record per row. The
// key-check preflight counts them to tell a fresh database from one whose key
// check went missing; a database with rows but no key check is refused rather
// than silently re-initialized.
var rowTables = []string{
	"users", "sessions", "invites", "contacts", "conversations",
	"messages", "attachments", "device_keys", "key_envelopes", "push_subscriptions",
}

// subMigrations exposes the embedded migration files to goose, rooted at the
// migrations directory so the provider sees them as plain .sql files.
func subMigrations() (fs.FS, error) {
	return fs.Sub(migrations, "migrations")
}

// sqliteURI builds a modernc.org/sqlite DSN. The path is escaped, because an
// unescaped '?' or '#' in the data directory would be read as the start of the
// query string or a fragment.
func sqliteURI(path string) (string, error) {
	abs, err := filepath.Abs(path)
	if err != nil {
		return "", err
	}
	u := &url.URL{Scheme: "file", Path: filepath.ToSlash(abs)}
	u.RawQuery = "_pragma=busy_timeout(10000)" +
		"&_pragma=journal_mode(WAL)" +
		"&_pragma=synchronous(FULL)" +
		"&_pragma=foreign_keys(ON)" +
		"&_txlock=immediate"
	return u.String(), nil
}

// errWrongKey is returned when the database (or the legacy snapshot) cannot be
// opened with the key at hand. It is deliberately distinct from "corrupt": the
// operator's fix is the key, not the file.
var errWrongKey = errors.New("store: the data key does not open this database")

// checkExistingKey verifies the key against an already-initialized database
// *before* any migration runs.
//
// This is the ordering that matters: goose would otherwise be free to write to
// a database it cannot read, so a wrong key would damage the file (or "helpfully"
// migrate a fresh-looking schema over real data) before the mismatch was
// noticed.
func (s *Store) checkExistingKey(db *sql.DB) error {
	var exists int
	if err := db.QueryRow("SELECT count(*) FROM sqlite_master WHERE type='table' AND name='metadata'").Scan(&exists); err != nil {
		return err
	}
	if exists == 0 {
		return nil // fresh database: nothing to check yet
	}
	var check []byte
	err := db.QueryRow("SELECT value FROM metadata WHERE key='key-check'").Scan(&check)
	if errors.Is(err, sql.ErrNoRows) {
		return nil // rows-but-no-check is handled after migrations, by preflight
	}
	if err != nil {
		return err
	}
	plain, err := s.unsealSnapshot(check)
	if err != nil {
		return fmt.Errorf("%w: %v", errWrongKey, err)
	}
	if string(plain) != sqliteKeyCheck {
		return errWrongKey
	}
	return nil
}

// sqliteKeyCheck is the plaintext sealed into the metadata row. It is a version
// marker, not a secret: it exists so a key either opens the database or is
// reported as wrong.
const sqliteKeyCheck = "ratatosk/sqlite/v1"

// importLegacy copies an existing sealed JSON snapshot into the new tables.
//
// It runs inside the same transaction that writes the key check, so a failure
// leaves the database empty and the snapshot untouched: the operator can fix
// the problem and start again. Nothing is deleted here — the snapshot stays on
// disk as the fallback, and `legacy-import` records that the copy happened.
func (s *Store) importLegacy(tx *sql.Tx) error {
	path := filepath.Join(s.dir, snapshotName)
	raw, err := os.ReadFile(path)
	if errors.Is(err, os.ErrNotExist) {
		return nil // nothing to import: a genuinely fresh install
	}
	if err != nil {
		return fmt.Errorf("store: read legacy snapshot: %w", err)
	}
	plain, err := s.unsealSnapshot(raw)
	if err != nil {
		// The snapshot is unreadable with this key. Refusing is the only safe answer:
		// importing "nothing" would look like a fresh install over real history.
		return fmt.Errorf("%w (legacy snapshot): %v", errWrongKey, err)
	}
	var db DB
	if err := json.Unmarshal(plain, &db); err != nil {
		return fmt.Errorf("store: parse legacy snapshot: %w", err)
	}
	if db.Version > dbVersion {
		return fmt.Errorf("store: legacy snapshot was written by a newer server (version %d > %d)", db.Version, dbVersion)
	}

	// Users first: every other table names one.
	for _, u := range db.Users {
		if u == nil {
			continue
		}
		if err := s.saveUser(tx, u); err != nil {
			return fmt.Errorf("store: import user %s: %w", u.ID, err)
		}
	}
	for _, v := range db.Sessions {
		if v == nil {
			continue
		}
		if err := s.put(tx, "sessions", v.Token, v, []string{"owner"}, s.rowID("users", v.UserID)); err != nil {
			return fmt.Errorf("store: import session: %w", err)
		}
	}
	for _, v := range db.Invites {
		if v == nil {
			continue
		}
		if err := s.put(tx, "invites", v.Code, v, []string{"owner"}, s.rowID("users", v.InviterID)); err != nil {
			return fmt.Errorf("store: import invite: %w", err)
		}
	}
	for owner, peers := range db.Contacts {
		for peer, since := range peers {
			row := &contactRow{Owner: owner, Peer: peer, Since: since}
			if err := s.put(tx, "contacts", contactID(owner, peer), row,
				[]string{"owner", "peer"}, s.rowID("users", owner), s.rowID("users", peer)); err != nil {
				return fmt.Errorf("store: import contact: %w", err)
			}
		}
	}
	for _, c := range db.Conversations {
		if c == nil {
			continue
		}
		if c.Members == nil {
			c.Members = map[string]*Member{}
		}
		if err := s.saveConversation(tx, c); err != nil {
			return fmt.Errorf("store: import conversation %s: %w", c.ID, err)
		}
	}
	// Messages in sequence order per conversation, so a partially imported
	// conversation still has a gapless prefix rather than a hole.
	for convID, ids := range db.ConvMessages {
		for _, id := range ids {
			m := db.Messages[id]
			if m == nil {
				continue
			}
			if m.ConversationID == "" {
				m.ConversationID = convID
			}
			if err := s.saveMessage(tx, m); err != nil {
				return fmt.Errorf("store: import message %s: %w", id, err)
			}
		}
	}
	// Anything the conversation index missed, so no message is silently dropped.
	for id, m := range db.Messages {
		if m == nil || db.Messages[id] == nil {
			continue
		}
		var n int
		if err := tx.QueryRow("SELECT count(*) FROM messages WHERE id=?", s.rowID("messages", id)).Scan(&n); err != nil {
			return err
		}
		if n != 0 {
			continue
		}
		if err := s.saveMessage(tx, m); err != nil {
			return fmt.Errorf("store: import message %s: %w", id, err)
		}
	}
	for _, a := range db.Attachments {
		if a == nil {
			continue
		}
		if err := s.put(tx, "attachments", a.ID, a, nil); err != nil {
			return fmt.Errorf("store: import attachment %s: %w", a.ID, err)
		}
	}
	for _, k := range db.DeviceKeys {
		if k == nil {
			continue
		}
		if err := s.put(tx, "device_keys", k.ID, k, []string{"owner"}, s.rowID("users", k.UserID)); err != nil {
			return fmt.Errorf("store: import device key %s: %w", k.ID, err)
		}
	}
	for _, e := range db.KeyEnvelopes {
		if e == nil {
			continue
		}
		if err := s.saveEnvelope(tx, e); err != nil {
			return fmt.Errorf("store: import key envelope %s: %w", e.ID, err)
		}
	}
	s.log.Info("imported legacy snapshot",
		"users", len(db.Users), "conversations", len(db.Conversations), "messages", len(db.Messages))
	return nil
}

// readLegacyView materializes the whole state as the old in-memory shape.
//
// It exists only for Store.View, which nothing in the server calls; the
// persistence model is one encrypted row per record, read through the typed
// methods. It is kept so that external callers of the old API keep compiling,
// and it is charged for accordingly: it decodes every row in the database.
func (s *Store) readLegacyView(q querier) (*DB, error) {
	db := newDB()
	users, err := listRows[User](s, q, "users", "")
	if err != nil {
		return nil, err
	}
	for _, u := range users {
		db.Users[u.ID] = u
	}
	sessions, err := listRows[Session](s, q, "sessions", "")
	if err != nil {
		return nil, err
	}
	for _, v := range sessions {
		db.Sessions[v.Token] = v
	}
	invites, err := listRows[Invite](s, q, "invites", "")
	if err != nil {
		return nil, err
	}
	for _, v := range invites {
		db.Invites[v.Code] = v
	}
	contacts, err := listRows[contactRow](s, q, "contacts", "")
	if err != nil {
		return nil, err
	}
	for _, c := range contacts {
		if db.Contacts[c.Owner] == nil {
			db.Contacts[c.Owner] = map[string]time.Time{}
		}
		db.Contacts[c.Owner][c.Peer] = c.Since
	}
	convs, err := listRows[Conversation](s, q, "conversations", "")
	if err != nil {
		return nil, err
	}
	for _, c := range convs {
		if c.Members == nil {
			c.Members = map[string]*Member{}
		}
		db.Conversations[c.ID] = c
	}
	msgs, err := listRows[Message](s, q, "messages", "ORDER BY conversation,seq")
	if err != nil {
		return nil, err
	}
	for _, m := range msgs {
		db.Messages[m.ID] = m
		db.ConvMessages[m.ConversationID] = append(db.ConvMessages[m.ConversationID], m.ID)
	}
	attachments, err := listRows[Attachment](s, q, "attachments", "")
	if err != nil {
		return nil, err
	}
	for _, a := range attachments {
		db.Attachments[a.ID] = a
	}
	keys, err := listRows[DeviceKey](s, q, "device_keys", "")
	if err != nil {
		return nil, err
	}
	for _, k := range keys {
		db.DeviceKeys[k.ID] = k
	}
	envelopes, err := listRows[KeyEnvelope](s, q, "key_envelopes", "")
	if err != nil {
		return nil, err
	}
	for _, e := range envelopes {
		db.KeyEnvelopes[e.ID] = e
	}
	return db, nil
}

// legacySnapshotDetected reports whether a sealed JSON snapshot is present.
// It is used for diagnostics, not for any data path.
func (s *Store) legacySnapshotDetected() bool {
	raw, err := os.ReadFile(filepath.Join(s.dir, snapshotName))
	return err == nil && strings.HasPrefix(string(raw), snapshotMagic)
}
