package store

import (
	"crypto/sha256"
	"database/sql"
	"encoding/hex"
	"errors"
	"sort"
	"time"

	"github.com/gokr/ratatosk/server/internal/ids"
)

// DeviceKey is the public half of one install's end-to-end encryption keys.
//
// The private halves never reach the server; these records are a directory, not
// a secret. Everything here is either public key material or metadata the
// server already knows (which account owns it, when it was seen).
type DeviceKey struct {
	ID        string `json:"id"`
	UserID    string `json:"userId"`
	Identity  []byte `json:"identityPublicKey"` // X25519
	Signing   []byte `json:"signingPublicKey"`  // Ed25519
	Label     string `json:"label,omitempty"`
	Platform  string `json:"platform,omitempty"`
	CreatedAt time.Time
	LastSeen  time.Time `json:"lastSeen"`
	Revoked   bool      `json:"revoked,omitempty"`
}

// Fingerprint is the canonical digest of a device key: its id and its public
// halves.
//
// It is defined here as well as on the client so the server can show the same
// value; the client always recomputes it rather than trusting this one.
//
// This is the *display* fingerprint — what a human compares when checking which
// device a key belongs to. Key derivation uses a digest of the public keys
// alone (docs/E2EE.md §2), so that the server-assigned id cannot influence any
// key: this value deliberately is not used for that.
func (d *DeviceKey) Fingerprint() string {
	h := sha256.New()
	h.Write([]byte("ratatosk/v1/fingerprint|"))
	h.Write([]byte(d.ID))
	h.Write([]byte("|"))
	h.Write(d.Identity)
	h.Write([]byte("|"))
	h.Write(d.Signing)
	return hex.EncodeToString(h.Sum(nil))
}

// KeyEnvelope is one recipient's copy of a sender key, sealed by the sender.
//
// The server cannot open it: `Wrapped` is XChaCha20-Poly1305 ciphertext under a
// key derived from the two devices' identity keys, and the AEAD's associated
// data binds the envelope to this conversation, sender key, epoch and
// recipient. Moving an envelope elsewhere makes it fail to open.
type KeyEnvelope struct {
	ID           string    `json:"id"`
	Conversation string    `json:"conversationId"`
	SenderKeyID  string    `json:"senderDeviceKeyId"`
	RecipientID  string    `json:"recipientDeviceKeyId"`
	Epoch        int32     `json:"epoch"`
	Wrapped      []byte    `json:"wrappedKey"`
	Nonce        []byte    `json:"nonce"`
	CreatedAt    time.Time `json:"createdAt"`
}

// maxWrappedKeyBytes and maxNonceBytes bound what a client can store per
// envelope. A sender key is 32 bytes and a nonce is 24; anything much larger is
// a client trying to use the server as free storage.
const (
	maxWrappedKeyBytes = 1024
	maxNonceBytes      = 64
)

// ErrInvalidKey is returned for key material that cannot be valid.
var ErrInvalidKey = errors.New("store: invalid key material")

func (s *Store) PublishDeviceKey(id, userID string, identity, signing []byte, label, platform string, now time.Time) (out *DeviceKey, err error) {
	if len(identity) != 32 || len(signing) != 32 {
		return nil, ErrInvalidKey
	}
	err = s.write(func(tx *sql.Tx) error {
		if _, e := getRow[User](s, tx, "users", userID); e != nil {
			if e == ErrNotFound {
				return ErrUnknownUser
			}
			return e
		}
		if id == "" {
			out = &DeviceKey{ID: ids.New("k"), UserID: userID, Identity: append([]byte(nil), identity...), Signing: append([]byte(nil), signing...), Label: label, Platform: platform, CreatedAt: now, LastSeen: now}
		} else {
			v, e := getRow[DeviceKey](s, tx, "device_keys", id)
			if e != nil {
				return e
			}
			if v.UserID != userID {
				return ErrNotFound
			}
			if !bytesEqual(v.Identity, identity) || !bytesEqual(v.Signing, signing) {
				return ErrInvalidKey
			}
			v.Label = label
			v.Platform = platform
			v.LastSeen = now
			v.Revoked = false
			out = v
		}
		return s.put(tx, "device_keys", out.ID, out, []string{"owner"}, s.rowID("users", userID))
	})
	if err != nil {
		return nil, err
	}
	return out, nil
}
func (s *Store) DeviceKeysOf(userID string, includeRevoked bool) []*DeviceKey {
	all, e := listRows[DeviceKey](s, s.sql, "device_keys", "WHERE owner=?", s.rowID("users", userID))
	must(e)
	out := make([]*DeviceKey, 0)
	for _, v := range all {
		if includeRevoked || !v.Revoked {
			out = append(out, v)
		}
	}
	sort.Slice(out, func(i, j int) bool { return out[i].CreatedAt.After(out[j].CreatedAt) })
	return out
}
func (s *Store) DeviceKeysOfUsers(userIDs []string, includeRevoked bool) []*DeviceKey {
	out := make([]*DeviceKey, 0)
	seen := map[string]bool{}
	for _, id := range userIDs {
		if !seen[id] {
			out = append(out, s.DeviceKeysOf(id, includeRevoked)...)
			seen[id] = true
		}
	}
	sort.Slice(out, func(i, j int) bool { return out[i].CreatedAt.After(out[j].CreatedAt) })
	return out
}
func (s *Store) DeviceKeyByID(id string) (*DeviceKey, error) {
	return getRow[DeviceKey](s, s.sql, "device_keys", id)
}
func (s *Store) RevokeDeviceKey(id, userID string) error {
	return s.write(func(tx *sql.Tx) error {
		v, e := getRow[DeviceKey](s, tx, "device_keys", id)
		if e != nil {
			return e
		}
		if v.UserID != userID {
			return ErrNotFound
		}
		v.Revoked = true
		if e = s.put(tx, "device_keys", id, v, []string{"owner"}, s.rowID("users", userID)); e != nil {
			return e
		}
		_, e = tx.Exec("DELETE FROM key_envelopes WHERE recipient=?", s.rowID("device_keys", id))
		return e
	})
}
func (s *Store) TouchDeviceKey(id string, now time.Time) {
	e := s.write(func(tx *sql.Tx) error {
		v, e := getRow[DeviceKey](s, tx, "device_keys", id)
		if e != nil {
			return e
		}
		v.LastSeen = now
		return s.put(tx, "device_keys", id, v, []string{"owner"}, s.rowID("users", v.UserID))
	})
	if e != ErrNotFound {
		must(e)
	}
}
func (s *Store) saveEnvelope(q querier, v *KeyEnvelope) error {
	return s.put(q, "key_envelopes", v.ID, v, []string{"conversation", "sender", "recipient", "epoch"}, s.rowID("conversations", v.Conversation), s.rowID("device_keys", v.SenderKeyID), s.rowID("device_keys", v.RecipientID), v.Epoch)
}
func (s *Store) PutKeyEnvelope(env *KeyEnvelope, now time.Time) (out *KeyEnvelope, err error) {
	if len(env.Wrapped) == 0 || len(env.Wrapped) > maxWrappedKeyBytes || len(env.Nonce) == 0 || len(env.Nonce) > maxNonceBytes {
		return nil, ErrInvalidKey
	}
	err = s.write(func(tx *sql.Tx) error {
		c, e := getRow[Conversation](s, tx, "conversations", env.Conversation)
		if e != nil {
			return e
		}
		for _, id := range []string{env.SenderKeyID, env.RecipientID} {
			k, e := getRow[DeviceKey](s, tx, "device_keys", id)
			if e != nil {
				return e
			}
			if k.Revoked {
				return ErrNotFound
			}
			if _, ok := c.Members[k.UserID]; !ok {
				return ErrNotMember
			}
		}
		all, e := listRows[KeyEnvelope](s, tx, "key_envelopes", "WHERE conversation=? AND sender=? AND recipient=? AND epoch=?", s.rowID("conversations", env.Conversation), s.rowID("device_keys", env.SenderKeyID), s.rowID("device_keys", env.RecipientID), env.Epoch)
		if e != nil {
			return e
		}
		if len(all) > 0 {
			out = all[0]
			return nil
		}
		out = cloneKeyEnvelope(env)
		out.ID = ids.New("e")
		out.CreatedAt = now
		return s.saveEnvelope(tx, out)
	})
	if err != nil {
		return nil, err
	}
	return out, nil
}
func (s *Store) ListKeyEnvelopes(recipientID, conversationID string, since time.Time) []*KeyEnvelope {
	where := "WHERE recipient=?"
	args := []any{s.rowID("device_keys", recipientID)}
	if conversationID != "" {
		where += " AND conversation=?"
		args = append(args, s.rowID("conversations", conversationID))
	}
	all, e := listRows[KeyEnvelope](s, s.sql, "key_envelopes", where, args...)
	must(e)
	out := make([]*KeyEnvelope, 0)
	for _, v := range all {
		if since.IsZero() || v.CreatedAt.After(since) {
			out = append(out, v)
		}
	}
	sort.Slice(out, func(i, j int) bool { return out[i].CreatedAt.After(out[j].CreatedAt) })
	return out
}
func (s *Store) CountKeyEnvelopes() int {
	var n int
	must(s.sql.QueryRow("SELECT count(*) FROM key_envelopes").Scan(&n))
	return n
}

func cloneDeviceKey(k *DeviceKey) *DeviceKey {
	c := *k
	c.Identity = append([]byte(nil), k.Identity...)
	c.Signing = append([]byte(nil), k.Signing...)
	return &c
}

func cloneKeyEnvelope(e *KeyEnvelope) *KeyEnvelope {
	c := *e
	c.Wrapped = append([]byte(nil), e.Wrapped...)
	c.Nonce = append([]byte(nil), e.Nonce...)
	return &c
}

func bytesEqual(a, b []byte) bool {
	if len(a) != len(b) {
		return false
	}
	for i := range a {
		if a[i] != b[i] {
			return false
		}
	}
	return true
}
