package store

import (
	"database/sql"
	"time"
)

// KeyBackup is an account's encrypted key backup.
//
// Every field except UserID and UpdatedAt is opaque: Salt, Nonce and Blob are
// produced on the device, and the KDF parameters describe how the user's
// passphrase was stretched into the key that sealed it. This server has no way to
// open any of it, which is the point — the backup is meant to survive the server
// being compromised.
type KeyBackup struct {
	UserID      string    `json:"userId"`
	Salt        []byte    `json:"salt"`
	Nonce       []byte    `json:"nonce"`
	Blob        []byte    `json:"blob"`
	KDF         string    `json:"kdf"`
	MemoryKiB   int       `json:"memoryKiB"`
	Iterations  int       `json:"iterations"`
	Parallelism int       `json:"parallelism"`
	Version     string    `json:"version"`
	UpdatedAt   time.Time `json:"updatedAt"`
}

// Limits on what a client may ask the server to store. A backup holds a few
// hundred bytes of key material, so anything approaching these bounds is either a
// client bug or an attempt to use the account as free storage.
const (
	maxKeyBackupBlob  = 64 * 1024
	maxKeyBackupSalt  = 64
	maxKeyBackupNonce = 32
	// Argon2id parameters a client may declare. The bounds are sanity checks, not
	// a policy: they stop a backup that claims a 4 GiB work factor (which would
	// make restore impossible on any phone) from being stored as if it were fine.
	minKeyBackupMemoryKiB   = 8 * 1024
	maxKeyBackupMemoryKiB   = 1024 * 1024
	maxKeyBackupIterations  = 64
	maxKeyBackupParallelism = 16
)

// PutKeyBackup stores (or replaces) the account's backup.
//
// Replacing is deliberate and is the only way to change it: a user who rotates
// their passphrase writes a new blob over the old one. There is no history of
// backups, because an old blob an attacker could fetch after a passphrase change
// would defeat the rotation.
func (s *Store) PutKeyBackup(b *KeyBackup) error {
	if b == nil || b.UserID == "" {
		return ErrInvalidKey
	}
	switch {
	case len(b.Blob) == 0 || len(b.Blob) > maxKeyBackupBlob:
		return ErrInvalidKey
	case len(b.Salt) == 0 || len(b.Salt) > maxKeyBackupSalt:
		return ErrInvalidKey
	case len(b.Nonce) == 0 || len(b.Nonce) > maxKeyBackupNonce:
		return ErrInvalidKey
	case b.KDF != "argon2id":
		return ErrInvalidKey
	case b.MemoryKiB < minKeyBackupMemoryKiB || b.MemoryKiB > maxKeyBackupMemoryKiB:
		return ErrInvalidKey
	case b.Iterations < 1 || b.Iterations > maxKeyBackupIterations:
		return ErrInvalidKey
	case b.Parallelism < 1 || b.Parallelism > maxKeyBackupParallelism:
		return ErrInvalidKey
	case b.Version == "":
		return ErrInvalidKey
	}
	return s.write(func(tx *sql.Tx) error {
		// The account must exist: a backup for nobody is unreachable data.
		if _, err := getRow[User](s, tx, "users", b.UserID); err != nil {
			return err
		}
		copy := *b
		copy.UpdatedAt = time.Now()
		return s.put(tx, "key_backups", copy.UserID, &copy, []string{"owner"}, s.rowID("users", copy.UserID))
	})
}

// KeyBackupOf returns the account's backup, or ErrNotFound when there is none.
func (s *Store) KeyBackupOf(userID string) (*KeyBackup, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	tx, err := s.sql.Begin()
	if err != nil {
		return nil, err
	}
	defer tx.Rollback()
	return getRow[KeyBackup](s, tx, "key_backups", userID)
}

// DeleteKeyBackup removes the account's backup. Deleting something that is not
// there is not an error: the caller asked for it to be gone, and it is.
func (s *Store) DeleteKeyBackup(userID string) error {
	return s.write(func(tx *sql.Tx) error {
		if _, err := getRow[KeyBackup](s, tx, "key_backups", userID); err == ErrNotFound {
			return nil
		} else if err != nil {
			return err
		}
		_, err := tx.Exec("DELETE FROM key_backups WHERE id=?", s.rowID("key_backups", userID))
		return err
	})
}
