package store

import (
	"bytes"
	"crypto/rand"
	"encoding/json"
	"io"
	"log/slog"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

func testLogger() *slog.Logger { return slog.New(slog.NewTextHandler(io.Discard, nil)) }

func testStore(t *testing.T) *Store {
	t.Helper()
	st, err := Open(t.TempDir(), testLogger())
	if err != nil {
		t.Fatalf("open store: %v", err)
	}
	t.Cleanup(func() { _ = st.Close() })
	return st
}

func randomBytes(t *testing.T, n int) []byte {
	t.Helper()
	b := make([]byte, n)
	if _, err := rand.Read(b); err != nil {
		t.Fatalf("rand: %v", err)
	}
	return b
}

// TestSnapshotIsEncryptedAtRest is the "server break-in" requirement: whatever
// the database holds must not be readable from the file.
func TestSnapshotIsEncryptedAtRest(t *testing.T) {
	dir := t.TempDir()
	st, err := Open(dir, testLogger())
	if err != nil {
		t.Fatalf("open store: %v", err)
	}
	user, err := st.CreateUser("ada", "Ada Lovelace", "hash", "salt", "#1da1f2", time.Now())
	if err != nil {
		t.Fatalf("create user: %v", err)
	}
	conv, err := st.CreateConversation(KindGroup, "Secret Club", user.ID, nil, time.Now())
	if err != nil {
		t.Fatalf("create conversation: %v", err)
	}
	if _, err := st.AppendMessage(&Message{
		ConversationID: conv.ID,
		SenderID:       user.ID,
		Text:           "the plaintext that must not touch the disk",
	}, time.Now()); err != nil {
		t.Fatalf("append: %v", err)
	}
	if err := st.Close(); err != nil {
		t.Fatalf("close: %v", err)
	}

	if !bytes.HasPrefix(cat(t, filepath.Join(dir, databaseName)), []byte("SQLite format 3")) {
		t.Fatal("the database is not a SQLite file")
	}
	// Every file the store wrote, checked for content a thief would look for.
	// Only distinctive values are searched for: a bare "ada" would match the
	// word "metadata" in the schema, which is not a leak.
	for _, secret := range []string{
		"the plaintext that must not touch the disk",
		"Secret Club",
		"Ada Lovelace",
	} {
		for _, name := range storeFiles(t, dir) {
			if bytes.Contains(cat(t, name), []byte(secret)) {
				t.Errorf("%s contains %q", filepath.Base(name), secret)
			}
		}
	}

	// The key file exists and is private.
	info, err := os.Stat(filepath.Join(dir, dataKeyFile))
	if err != nil {
		t.Fatalf("stat key file: %v", err)
	}
	if perm := info.Mode().Perm(); perm != 0o600 {
		t.Errorf("key file permissions = %o, want 600", perm)
	}

	// Reopening with the key present restores everything.
	reopened, err := Open(dir, testLogger())
	if err != nil {
		t.Fatalf("reopen: %v", err)
	}
	defer reopened.Close()
	msgs, _, err := reopened.MessagesOf(conv.ID, 0, 0, 10)
	if err != nil {
		t.Fatalf("list: %v", err)
	}
	if len(msgs) != 1 || msgs[0].Text != "the plaintext that must not touch the disk" {
		t.Fatalf("messages after reopen = %v", msgs)
	}
}

// A snapshot sealed with a different key must refuse to open rather than start
// an empty database over it: silently losing history is worse than failing.
func TestSnapshotWithTheWrongKeyRefusesToOpen(t *testing.T) {
	dir := t.TempDir()
	st, err := Open(dir, testLogger())
	if err != nil {
		t.Fatalf("open: %v", err)
	}
	if _, err := st.CreateUser("ada", "", "h", "s", "#fff", time.Now()); err != nil {
		t.Fatalf("create user: %v", err)
	}
	if err := st.Close(); err != nil {
		t.Fatalf("close: %v", err)
	}

	t.Setenv(dataKeyEnvVar, strings.Repeat("ab", keyBytes))
	if _, err := Open(dir, testLogger()); err == nil {
		t.Fatal("opening the database with the wrong key succeeded")
	} else if !strings.Contains(err.Error(), "data key") {
		t.Fatalf("error = %v, want a data key failure", err)
	}
}

// A sealed JSON snapshot from the pre-SQLite server is imported on first boot,
// and the snapshot is left in place as the fallback rather than deleted.
func TestLegacyEncryptedSnapshotIsImported(t *testing.T) {
	dir := t.TempDir()
	key := strings.Repeat("ab", keyBytes)
	t.Setenv(dataKeyEnvVar, key)

	if _, err := os.Stat(filepath.Join(dir, "data-key")); err == nil {
		t.Fatal("test writes its own key file")
	}
	st, err := Open(dir, testLogger())
	if err != nil {
		t.Fatalf("open: %v", err)
	}
	user, err := st.CreateUser("ada", "Ada Lovelace", "h", "s", "#fff", time.Now())
	if err != nil {
		t.Fatalf("create user: %v", err)
	}
	conv, err := st.CreateConversation(KindGroup, "Secret Club", user.ID, nil, time.Now())
	if err != nil {
		t.Fatalf("create conversation: %v", err)
	}
	if _, err := st.AppendMessage(&Message{ConversationID: conv.ID, SenderID: user.ID, Text: "before the migration"}, time.Now()); err != nil {
		t.Fatalf("append: %v", err)
	}
	// Turn back the clock: write the same state as the old sealed snapshot and
	// remove the SQLite database, as an upgrade from an older server would look.
	if err := writeLegacySnapshot(t, st, filepath.Join(dir, snapshotName)); err != nil {
		t.Fatalf("write legacy snapshot: %v", err)
	}
	if err := st.Close(); err != nil {
		t.Fatalf("close: %v", err)
	}
	for _, name := range []string{databaseName, databaseName + "-wal", databaseName + "-shm"} {
		_ = os.Remove(filepath.Join(dir, name))
	}

	imported, err := Open(dir, testLogger())
	if err != nil {
		t.Fatalf("import legacy snapshot: %v", err)
	}
	defer imported.Close()

	if got := imported.Stats(); got.Users != 1 || got.Conversations != 1 || got.Messages != 1 {
		t.Fatalf("stats after import = %+v, want 1 user, 1 conversation, 1 message", got)
	}
	back, _, err := imported.MessagesOf(conv.ID, 0, 0, 10)
	if err != nil || len(back) != 1 || back[0].Text != "before the migration" {
		t.Fatalf("messages after import = %v (%v)", back, err)
	}
	if _, err := imported.UserByUsername("ada"); err != nil {
		t.Fatalf("user after import: %v", err)
	}
	// The snapshot is kept: it is the fallback if the import is ever wrong.
	if _, err := os.Stat(filepath.Join(dir, snapshotName)); err != nil {
		t.Fatalf("legacy snapshot was removed: %v", err)
	}
}

// A snapshot that does not decrypt with the current key must refuse to boot,
// rather than importing nothing over real history.
func TestUnreadableLegacySnapshotRefusesToStart(t *testing.T) {
	dir := t.TempDir()
	key := strings.Repeat("ab", keyBytes)
	t.Setenv(dataKeyEnvVar, key)
	st, err := Open(dir, testLogger())
	if err != nil {
		t.Fatalf("open: %v", err)
	}
	if _, err := st.CreateUser("ada", "Ada", "h", "s", "#fff", time.Now()); err != nil {
		t.Fatalf("create user: %v", err)
	}
	if err := writeLegacySnapshot(t, st, filepath.Join(dir, snapshotName)); err != nil {
		t.Fatalf("write legacy snapshot: %v", err)
	}
	if err := st.Close(); err != nil {
		t.Fatalf("close: %v", err)
	}
	for _, name := range []string{databaseName, databaseName + "-wal", databaseName + "-shm"} {
		_ = os.Remove(filepath.Join(dir, name))
	}

	// A different key cannot read the snapshot.
	t.Setenv(dataKeyEnvVar, strings.Repeat("cd", keyBytes))
	if _, err := Open(dir, testLogger()); err == nil {
		t.Fatal("an unreadable legacy snapshot was ignored and the store started empty")
	}
}

// writeLegacySnapshot seals the store's current state as the old JSON snapshot.
func writeLegacySnapshot(t *testing.T, st *Store, path string) error {
	t.Helper()
	var db *DB
	if err := st.View(func(view *DB) error { db = view; return nil }); err != nil {
		return err
	}
	plain, err := json.Marshal(db)
	if err != nil {
		return err
	}
	sealed, err := st.sealSnapshot(plain)
	if err != nil {
		return err
	}
	return os.WriteFile(path, sealed, 0o600)
}

// storeFiles lists every file the store wrote except the key file, which is hex
// key material rather than content.
func storeFiles(t *testing.T, dir string) []string {
	t.Helper()
	var out []string
	err := filepath.Walk(dir, func(path string, info os.FileInfo, err error) error {
		if err != nil || info.IsDir() || filepath.Base(path) == dataKeyFile {
			return err
		}
		out = append(out, path)
		return nil
	})
	if err != nil {
		t.Fatalf("walk: %v", err)
	}
	return out
}

func cat(t *testing.T, path string) []byte {
	t.Helper()
	raw, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("read %s: %v", path, err)
	}
	return raw
}

func TestDeviceKeysAreImmutableAndPrivate(t *testing.T) {
	st := testStore(t)
	now := time.Now()
	ada, err := st.CreateUser("ada", "", "h", "s", "#fff", now)
	if err != nil {
		t.Fatalf("create user: %v", err)
	}
	grace, err := st.CreateUser("grace", "", "h", "s", "#fff", now)
	if err != nil {
		t.Fatalf("create user: %v", err)
	}

	identity := randomBytes(t, 32)
	signing := randomBytes(t, 32)
	key, err := st.PublishDeviceKey("", ada.ID, identity, signing, "Laptop", "linux", now)
	if err != nil {
		t.Fatalf("publish: %v", err)
	}
	if len(key.Fingerprint()) != 64 {
		t.Fatalf("fingerprint = %q, want 64 hex chars", key.Fingerprint())
	}

	// The same keys may be re-published (a client restarting, say).
	if _, err := st.PublishDeviceKey(key.ID, ada.ID, identity, signing, "Renamed", "linux", now); err != nil {
		t.Fatalf("re-publish: %v", err)
	}

	// Different key material under the same id is refused: a device key that
	// could change would invalidate every safety number recorded against it.
	if _, err := st.PublishDeviceKey(key.ID, ada.ID, randomBytes(t, 32), signing, "x", "linux", now); err != ErrInvalidKey {
		t.Fatalf("key substitution: err = %v, want ErrInvalidKey", err)
	}
	// Somebody else's key id cannot be taken over.
	if _, err := st.PublishDeviceKey(key.ID, grace.ID, identity, signing, "x", "linux", now); err != ErrNotFound {
		t.Fatalf("foreign publish: err = %v, want ErrNotFound", err)
	}
	// Wrong sizes are refused.
	if _, err := st.PublishDeviceKey("", ada.ID, randomBytes(t, 16), signing, "", "", now); err != ErrInvalidKey {
		t.Fatalf("short key: err = %v, want ErrInvalidKey", err)
	}
}

func TestKeyEnvelopesRequireSharedMembership(t *testing.T) {
	st := testStore(t)
	now := time.Now()
	ada, _ := st.CreateUser("ada", "", "h", "s", "#fff", now)
	grace, _ := st.CreateUser("grace", "", "h", "s", "#fff", now)
	mallory, _ := st.CreateUser("mallory", "", "h", "s", "#fff", now)

	adaKey, err := st.PublishDeviceKey("", ada.ID, randomBytes(t, 32), randomBytes(t, 32), "", "", now)
	if err != nil {
		t.Fatalf("publish ada: %v", err)
	}
	graceKey, err := st.PublishDeviceKey("", grace.ID, randomBytes(t, 32), randomBytes(t, 32), "", "", now)
	if err != nil {
		t.Fatalf("publish grace: %v", err)
	}
	malloryKey, err := st.PublishDeviceKey("", mallory.ID, randomBytes(t, 32), randomBytes(t, 32), "", "", now)
	if err != nil {
		t.Fatalf("publish mallory: %v", err)
	}

	conv, err := st.CreateConversation(KindGroup, "Club", ada.ID, []string{grace.ID}, now)
	if err != nil {
		t.Fatalf("create conversation: %v", err)
	}

	envelope, err := st.PutKeyEnvelope(&KeyEnvelope{
		Conversation: conv.ID,
		SenderKeyID:  adaKey.ID,
		RecipientID:  graceKey.ID,
		Epoch:        0,
		Wrapped:      randomBytes(t, 48),
		Nonce:        randomBytes(t, 24),
	}, now)
	if err != nil {
		t.Fatalf("put envelope: %v", err)
	}
	// Retrying the same distribution must not stack up copies.
	if _, err := st.PutKeyEnvelope(&KeyEnvelope{
		Conversation: conv.ID,
		SenderKeyID:  adaKey.ID,
		RecipientID:  graceKey.ID,
		Epoch:        0,
		Wrapped:      randomBytes(t, 48),
		Nonce:        randomBytes(t, 24),
	}, now); err != nil {
		t.Fatalf("repeat envelope: %v", err)
	}
	if n := st.CountKeyEnvelopes(); n != 1 {
		t.Fatalf("envelope count = %d, want 1", n)
	}

	// A device outside the conversation is refused, so the service cannot be
	// used as a blind relay.
	if _, err := st.PutKeyEnvelope(&KeyEnvelope{
		Conversation: conv.ID,
		SenderKeyID:  adaKey.ID,
		RecipientID:  malloryKey.ID,
		Wrapped:      randomBytes(t, 48),
		Nonce:        randomBytes(t, 24),
	}, now); err != ErrNotMember {
		t.Fatalf("foreign envelope: err = %v, want ErrNotMember", err)
	}

	// Only the addressed device sees it.
	if got := st.ListKeyEnvelopes(graceKey.ID, "", time.Time{}); len(got) != 1 {
		t.Fatalf("grace envelopes = %d, want 1", len(got))
	}
	if got := st.ListKeyEnvelopes(malloryKey.ID, "", time.Time{}); len(got) != 0 {
		t.Fatalf("mallory envelopes = %d, want 0", len(got))
	}
	if got := st.ListKeyEnvelopes(graceKey.ID, conv.ID, envelope.CreatedAt); len(got) != 0 {
		t.Fatalf("envelopes after its own timestamp = %d, want 0", len(got))
	}

	// Revoking drops the envelopes addressed to a device: a key that is no
	// longer trusted must not be able to fetch its sender keys again.
	if err := st.RevokeDeviceKey(graceKey.ID, grace.ID); err != nil {
		t.Fatalf("revoke: %v", err)
	}
	if got := st.ListKeyEnvelopes(graceKey.ID, "", time.Time{}); len(got) != 0 {
		t.Fatalf("envelopes after revoke = %d, want 0", len(got))
	}
	if got := st.DeviceKeysOf(grace.ID, false); len(got) != 0 {
		t.Fatalf("active keys after revoke = %d, want 0", len(got))
	}
	if got := st.DeviceKeysOf(grace.ID, true); len(got) != 1 {
		t.Fatalf("all keys after revoke = %d, want 1", len(got))
	}
}

// An encrypted message stores bytes the server cannot read, and the validation
// that protects plaintext messages must not reject it.
func TestEncryptedMessagesStoreOpaqueBytes(t *testing.T) {
	st := testStore(t)
	now := time.Now()
	ada, _ := st.CreateUser("ada", "", "h", "s", "#fff", now)
	conv, _ := st.CreateConversation(KindGroup, "Club", ada.ID, nil, now)

	ciphertext := randomBytes(t, 128)
	saved, err := st.AppendMessage(&Message{
		ConversationID:    conv.ID,
		SenderID:          ada.ID,
		Kind:              MessageText,
		Ciphertext:        ciphertext,
		Nonce:             randomBytes(t, 24),
		SenderDeviceKeyID: "k1",
		CryptoVersion:     "ratatosk/v1",
	}, now)
	if err != nil {
		t.Fatalf("append encrypted: %v", err)
	}
	if !saved.Encrypted() {
		t.Fatal("the stored message does not report itself as encrypted")
	}
	if saved.Text != "" {
		t.Fatal("an encrypted message must not carry plaintext")
	}

	// Sealed bytes without a nonce or version could never be opened, so they
	// are refused rather than stored as a permanent unreadable row.
	if _, err := st.AppendMessage(&Message{
		ConversationID: conv.ID, SenderID: ada.ID, Kind: MessageText, Ciphertext: randomBytes(t, 32),
	}, now); err != ErrInvalidMessage {
		t.Fatalf("incomplete seal: err = %v, want ErrInvalidMessage", err)
	}

	// A message with neither plaintext nor ciphertext is still refused.
	if _, err := st.AppendMessage(&Message{
		ConversationID: conv.ID, SenderID: ada.ID, Kind: MessageText, Text: "   ",
	}, now); err != ErrInvalidMessage {
		t.Fatalf("empty message: err = %v, want ErrInvalidMessage", err)
	}

	// The stored row survives a restart with its bytes intact.
	dir := st.Dir()
	if err := st.Close(); err != nil {
		t.Fatalf("close: %v", err)
	}
	reopened, err := Open(dir, testLogger())
	if err != nil {
		t.Fatalf("reopen: %v", err)
	}
	defer reopened.Close()
	got, err := reopened.MessageByID(saved.ID)
	if err != nil {
		t.Fatalf("load: %v", err)
	}
	if !bytes.Equal(got.Ciphertext, ciphertext) {
		t.Fatal("the sealed bytes changed across a restart")
	}
}
