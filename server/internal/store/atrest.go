// Encryption at rest for the store snapshot.
//
// End-to-end encryption keeps message content away from the server; this keeps
// everything the server does hold — accounts, the social graph, conversation
// membership, timestamps, system notes, message sizes — out of reach of anyone
// who gets the database file without the key: a stolen disk, a backup, a
// container image.
//
// The key is deliberately not in the database. It comes from
// RATATOSK_DATA_KEY (hex or base64, 32 bytes) or, if unset, from a generated
// `data-key` file with 0600 permissions in the data directory. Anyone who has
// the data directory has the key file too, which is the honest limit of this
// arrangement: it protects a copy of the database (a backup, a dump, a disk
// image of another host), not the running server's own disk.
package store

import (
	"bytes"
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"encoding/base64"
	"encoding/hex"
	"errors"
	"fmt"
	"log/slog"
	"os"
	"path/filepath"
	"strings"
)

// snapshotHeader marks an encrypted snapshot and carries the format version.
// A plaintext JSON snapshot starts with '{', so the two cannot be confused.
const (
	snapshotMagic    = "RATATOSK-ENC-1\n"
	dataKeyFile      = "data-key"
	dataKeyEnvVar    = "RATATOSK_DATA_KEY"
	keyBytes         = 32 // AES-256
	nonceBytesAtRest = 12
)

// ErrNoDataKey is returned when the data key is missing and cannot be created.
var ErrNoDataKey = errors.New("store: no data encryption key")

// dataKey loads the key used to seal the snapshot, creating one on first use.
func (s *Store) dataKey() ([]byte, error) {
	s.keyOnce.Do(func() {
		s.dataKeyValue, s.keyErr = loadOrCreateDataKey(s.dir)
	})
	return s.dataKeyValue, s.keyErr
}

func loadOrCreateDataKey(dir string) ([]byte, error) {
	if raw := strings.TrimSpace(os.Getenv(dataKeyEnvVar)); raw != "" {
		key, err := decodeKey(raw)
		if err != nil {
			return nil, fmt.Errorf("store: %s: %w", dataKeyEnvVar, err)
		}
		return key, nil
	}

	path := filepath.Join(dir, dataKeyFile)
	switch raw, err := os.ReadFile(path); {
	case err == nil:
		key, decErr := decodeKey(strings.TrimSpace(string(raw)))
		if decErr != nil {
			return nil, fmt.Errorf("store: %s: %w", path, decErr)
		}
		return key, nil
	case !errors.Is(err, os.ErrNotExist):
		return nil, fmt.Errorf("store: read %s: %w", path, err)
	}

	key := make([]byte, keyBytes)
	if _, err := rand.Read(key); err != nil {
		return nil, fmt.Errorf("store: generate data key: %w", err)
	}
	// Write with 0600 and no partial file visible: a half-written key file
	// would make the database unreadable on the next start.
	tmp := path + ".tmp"
	if err := os.WriteFile(tmp, []byte(hex.EncodeToString(key)), 0o600); err != nil {
		return nil, fmt.Errorf("store: write %s: %w", tmp, err)
	}
	if err := os.Rename(tmp, path); err != nil {
		return nil, fmt.Errorf("store: commit %s: %w", path, err)
	}
	// Logged through the default logger: this runs before the caller's logger
	// is wired into the store's load path.
	slog.Default().Info("store: generated a data encryption key", "path", path)
	return key, nil
}

// decodeKey accepts hex or base64, so an operator can paste either.
func decodeKey(raw string) ([]byte, error) {
	if len(raw) == keyBytes*2 {
		if key, err := hex.DecodeString(raw); err == nil {
			return key, nil
		}
	}
	key, err := base64.StdEncoding.DecodeString(raw)
	if err != nil {
		return nil, errors.New("key must be 32 bytes, hex or base64 encoded")
	}
	if len(key) != keyBytes {
		return nil, fmt.Errorf("key must be 32 bytes, got %d", len(key))
	}
	return key, nil
}

// sealSnapshot encrypts a serialized database with AES-256-GCM.
//
// The magic header is authenticated as associated data, so a truncated or
// re-headed file fails to open rather than being parsed as JSON.
func (s *Store) sealSnapshot(plain []byte) ([]byte, error) {
	key, err := s.dataKey()
	if err != nil {
		return nil, err
	}
	block, err := aes.NewCipher(key)
	if err != nil {
		return nil, fmt.Errorf("store: cipher: %w", err)
	}
	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return nil, fmt.Errorf("store: gcm: %w", err)
	}
	nonce := make([]byte, nonceBytesAtRest)
	if _, err := rand.Read(nonce); err != nil {
		return nil, fmt.Errorf("store: nonce: %w", err)
	}
	out := make([]byte, 0, len(snapshotMagic)+len(nonce)+len(plain)+gcm.Overhead())
	out = append(out, snapshotMagic...)
	out = append(out, nonce...)
	return gcm.Seal(out, nonce, plain, []byte(snapshotMagic)), nil
}

// unsealSnapshot reverses sealSnapshot. A snapshot without the magic header is
// returned unchanged so a database written before encryption existed still
// loads; it is re-sealed on the next flush.
func (s *Store) unsealSnapshot(raw []byte) ([]byte, error) {
	if !bytes.HasPrefix(raw, []byte(snapshotMagic)) {
		if len(raw) > 0 && raw[0] == '{' {
			return raw, nil // legacy plaintext snapshot
		}
		return nil, errors.New("store: snapshot is neither encrypted nor JSON; refusing to guess")
	}
	key, err := s.dataKey()
	if err != nil {
		return nil, err
	}
	body := raw[len(snapshotMagic):]
	if len(body) < nonceBytesAtRest {
		return nil, errors.New("store: encrypted snapshot is truncated")
	}
	block, err := aes.NewCipher(key)
	if err != nil {
		return nil, err
	}
	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return nil, err
	}
	plain, err := gcm.Open(nil, body[:nonceBytesAtRest], body[nonceBytesAtRest:], []byte(snapshotMagic))
	if err != nil {
		return nil, fmt.Errorf("store: cannot decrypt the snapshot (%w): wrong %s, or the file was altered", err, dataKeyEnvVar)
	}
	return plain, nil
}
