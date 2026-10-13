package store

import (
	"bytes"
	"testing"
	"time"
)

// The key backup is what makes a reinstall survivable: without it the device
// private keys exist only in that device's keystore, and history is unreadable for
// good. These tests cover the parts the server is responsible for.
// testUser creates an account to hang a backup on.
func testUser(t *testing.T, st *Store, username string) *User {
	t.Helper()
	u, err := st.CreateUser(username, username, "h", "s", "#fff", time.Now())
	if err != nil {
		t.Fatalf("create user %s: %v", username, err)
	}
	return u
}

func validBackup(userID string) *KeyBackup {
	return &KeyBackup{
		UserID:      userID,
		Salt:        bytes.Repeat([]byte{1}, 16),
		Nonce:       bytes.Repeat([]byte{2}, 24),
		Blob:        bytes.Repeat([]byte{3}, 256),
		KDF:         "argon2id",
		MemoryKiB:   64 * 1024,
		Iterations:  3,
		Parallelism: 2,
		Version:     "ratatosk/keys/v1",
	}
}

func TestKeyBackupRoundTrips(t *testing.T) {
	st := testStore(t)
	u := testUser(t, st, "ada")

	// No backup yet is not an error: it is the normal state, and the client needs
	// to tell that apart from a failure.
	if _, err := st.KeyBackupOf(u.ID); err != ErrNotFound {
		t.Fatalf("empty: err = %v, want ErrNotFound", err)
	}

	want := validBackup(u.ID)
	want.Blob = []byte("sealed key material")
	if err := st.PutKeyBackup(want); err != nil {
		t.Fatalf("put: %v", err)
	}
	got, err := st.KeyBackupOf(u.ID)
	if err != nil {
		t.Fatalf("get: %v", err)
	}
	if !bytes.Equal(got.Blob, want.Blob) {
		t.Errorf("blob = %q, want %q", got.Blob, want.Blob)
	}
	// The KDF parameters must survive: a restore that guessed them would derive
	// the wrong key and the backup would be unopenable.
	if got.KDF != "argon2id" || got.MemoryKiB != want.MemoryKiB ||
		got.Iterations != want.Iterations || got.Parallelism != want.Parallelism {
		t.Errorf("kdf parameters not preserved: %+v", got)
	}
	if got.Version != want.Version {
		t.Errorf("version = %q, want %q", got.Version, want.Version)
	}
	if got.UpdatedAt.IsZero() {
		t.Error("UpdatedAt was not set by the store")
	}

	// Replacing is how a passphrase rotation is expressed.
	second := validBackup(u.ID)
	second.Blob = []byte("rotated")
	if err := st.PutKeyBackup(second); err != nil {
		t.Fatalf("replace: %v", err)
	}
	got, err = st.KeyBackupOf(u.ID)
	if err != nil {
		t.Fatalf("get after replace: %v", err)
	}
	if string(got.Blob) != "rotated" {
		t.Errorf("blob = %q, want the replacement", got.Blob)
	}
}

// One account's backup must never be reachable as another's.
func TestKeyBackupIsPerAccount(t *testing.T) {
	st := testStore(t)
	ada := testUser(t, st, "ada")
	grace := testUser(t, st, "grace")

	if err := st.PutKeyBackup(validBackup(ada.ID)); err != nil {
		t.Fatalf("put ada: %v", err)
	}
	if _, err := st.KeyBackupOf(grace.ID); err != ErrNotFound {
		t.Fatalf("grace sees a backup: err = %v", err)
	}
	if err := st.DeleteKeyBackup(grace.ID); err != nil {
		t.Fatalf("deleting a backup that is not there must succeed: %v", err)
	}
	if _, err := st.KeyBackupOf(ada.ID); err != nil {
		t.Fatalf("grace's delete removed ada's backup: %v", err)
	}
}

// A backup nobody could restore is worse than none, because it is believed in.
func TestKeyBackupRejectsUnrestorableParameters(t *testing.T) {
	st := testStore(t)
	u := testUser(t, st, "ada")

	cases := map[string]func(*KeyBackup){
		"empty blob":      func(b *KeyBackup) { b.Blob = nil },
		"empty salt":      func(b *KeyBackup) { b.Salt = nil },
		"empty nonce":     func(b *KeyBackup) { b.Nonce = nil },
		"unknown kdf":     func(b *KeyBackup) { b.KDF = "md5" },
		"absurd memory":   func(b *KeyBackup) { b.MemoryKiB = 4 * 1024 * 1024 },
		"zero iterations": func(b *KeyBackup) { b.Iterations = 0 },
		"no parallelism":  func(b *KeyBackup) { b.Parallelism = 0 },
		"no version":      func(b *KeyBackup) { b.Version = "" },
		"oversized blob":  func(b *KeyBackup) { b.Blob = bytes.Repeat([]byte{1}, 128*1024) },
	}
	for name, mutate := range cases {
		b := validBackup(u.ID)
		mutate(b)
		if err := st.PutKeyBackup(b); err != ErrInvalidKey {
			t.Errorf("%s: err = %v, want ErrInvalidKey", name, err)
		}
	}
	if _, err := st.KeyBackupOf(u.ID); err != ErrNotFound {
		t.Error("a rejected backup was stored anyway")
	}
}

// Deleting the account must take the backup with it: a blob of key material that
// belongs to nobody is a liability, and a reused username must not inherit it.
func TestDeleteUserRemovesTheKeyBackup(t *testing.T) {
	st := testStore(t)
	u := testUser(t, st, "ada")
	if err := st.PutKeyBackup(validBackup(u.ID)); err != nil {
		t.Fatalf("put: %v", err)
	}
	if _, err := st.DeleteUser(u.ID); err != nil {
		t.Fatalf("delete user: %v", err)
	}
	if _, err := st.KeyBackupOf(u.ID); err != ErrNotFound {
		t.Errorf("the backup outlived the account: err = %v", err)
	}
}
