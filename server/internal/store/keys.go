package store

import (
	"crypto/sha256"
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

// Fingerprint is the canonical digest of a device key's public halves.
//
// It is defined here as well as on the client so the server can show the same
// value; the client always recomputes it rather than trusting this one.
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

// PublishDeviceKey registers or updates a device key.
//
// On update only the label may change: the key material is immutable, because a
// device key that silently changed its public key would defeat every safety
// number and pin a client had recorded. A client that wants new key material
// publishes a new device key.
func (s *Store) PublishDeviceKey(id, userID string, identity, signing []byte, label, platform string, now time.Time) (*DeviceKey, error) {
	if len(identity) != 32 || len(signing) != 32 {
		return nil, ErrInvalidKey
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	if _, ok := s.db.Users[userID]; !ok {
		return nil, ErrUnknownUser
	}

	if id == "" {
		id = ids.New("k")
		key := &DeviceKey{
			ID:        id,
			UserID:    userID,
			Identity:  append([]byte(nil), identity...),
			Signing:   append([]byte(nil), signing...),
			Label:     label,
			Platform:  platform,
			CreatedAt: now,
			LastSeen:  now,
		}
		s.db.DeviceKeys[id] = key
		s.markDirty()
		return cloneDeviceKey(key), nil
	}

	existing, ok := s.db.DeviceKeys[id]
	if !ok || existing.UserID != userID {
		// Unknown id, or somebody else's key: refuse rather than create or
		// hijack, so one account can never overwrite another's key material.
		return nil, ErrNotFound
	}
	if !bytesEqual(existing.Identity, identity) || !bytesEqual(existing.Signing, signing) {
		return nil, ErrInvalidKey
	}
	existing.Label = label
	existing.Platform = platform
	existing.LastSeen = now
	existing.Revoked = false
	s.markDirty()
	return cloneDeviceKey(existing), nil
}

// DeviceKeysOf lists a user's keys, newest first.
func (s *Store) DeviceKeysOf(userID string, includeRevoked bool) []*DeviceKey {
	s.mu.RLock()
	defer s.mu.RUnlock()
	var out []*DeviceKey
	for _, k := range s.db.DeviceKeys {
		if k.UserID != userID {
			continue
		}
		if k.Revoked && !includeRevoked {
			continue
		}
		out = append(out, cloneDeviceKey(k))
	}
	sort.Slice(out, func(i, j int) bool { return out[i].CreatedAt.After(out[j].CreatedAt) })
	return out
}

// DeviceKeysOfUsers lists the keys of several users at once, for the member
// list of a conversation.
func (s *Store) DeviceKeysOfUsers(userIDs []string, includeRevoked bool) []*DeviceKey {
	want := make(map[string]struct{}, len(userIDs))
	for _, id := range userIDs {
		want[id] = struct{}{}
	}
	s.mu.RLock()
	defer s.mu.RUnlock()
	var out []*DeviceKey
	for _, k := range s.db.DeviceKeys {
		if _, ok := want[k.UserID]; !ok {
			continue
		}
		if k.Revoked && !includeRevoked {
			continue
		}
		out = append(out, cloneDeviceKey(k))
	}
	sort.Slice(out, func(i, j int) bool { return out[i].CreatedAt.After(out[j].CreatedAt) })
	return out
}

// DeviceKeyByID returns one key, revoked or not.
func (s *Store) DeviceKeyByID(id string) (*DeviceKey, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	k, ok := s.db.DeviceKeys[id]
	if !ok {
		return nil, ErrNotFound
	}
	return cloneDeviceKey(k), nil
}

// RevokeDeviceKey marks a key unusable and drops the envelopes addressed to it.
//
// Deleting the envelopes matters: they are the only copies of the sender keys
// that device could read, and a revoked device should not be able to fetch them
// again if its session is somehow still valid.
func (s *Store) RevokeDeviceKey(id, userID string) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	k, ok := s.db.DeviceKeys[id]
	if !ok || k.UserID != userID {
		return ErrNotFound
	}
	k.Revoked = true
	for envID, env := range s.db.KeyEnvelopes {
		if env.RecipientID == id {
			delete(s.db.KeyEnvelopes, envID)
		}
	}
	s.markDirty()
	return nil
}

// TouchDeviceKey records that a device is still in use.
func (s *Store) TouchDeviceKey(id string, now time.Time) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if k, ok := s.db.DeviceKeys[id]; ok {
		k.LastSeen = now
		s.markDirty()
	}
}

// PutKeyEnvelope stores one sealed sender key.
//
// Envelopes are idempotent on (conversation, sender key, epoch, recipient): a
// sender that retries a distribution must not create a second copy, and a
// receiver that has already stored the key does not care which copy arrived.
func (s *Store) PutKeyEnvelope(env *KeyEnvelope, now time.Time) (*KeyEnvelope, error) {
	if len(env.Wrapped) == 0 || len(env.Wrapped) > maxWrappedKeyBytes {
		return nil, ErrInvalidKey
	}
	if len(env.Nonce) == 0 || len(env.Nonce) > maxNonceBytes {
		return nil, ErrInvalidKey
	}
	s.mu.Lock()
	defer s.mu.Unlock()

	c, ok := s.db.Conversations[env.Conversation]
	if !ok {
		return nil, ErrNotFound
	}
	sender, ok := s.db.DeviceKeys[env.SenderKeyID]
	if !ok || sender.Revoked {
		return nil, ErrNotFound
	}
	recipient, ok := s.db.DeviceKeys[env.RecipientID]
	if !ok || recipient.Revoked {
		return nil, ErrNotFound
	}
	// Both devices must belong to members of the conversation. Without this, a
	// member could deposit envelopes to arbitrary devices and the server would
	// happily relay them.
	if _, member := c.Members[sender.UserID]; !member {
		return nil, ErrNotMember
	}
	if _, member := c.Members[recipient.UserID]; !member {
		return nil, ErrNotMember
	}

	for _, existing := range s.db.KeyEnvelopes {
		if existing.Conversation == env.Conversation &&
			existing.SenderKeyID == env.SenderKeyID &&
			existing.RecipientID == env.RecipientID &&
			existing.Epoch == env.Epoch {
			return cloneKeyEnvelope(existing), nil
		}
	}

	out := &KeyEnvelope{
		ID:           ids.New("e"),
		Conversation: env.Conversation,
		SenderKeyID:  env.SenderKeyID,
		RecipientID:  env.RecipientID,
		Epoch:        env.Epoch,
		Wrapped:      append([]byte(nil), env.Wrapped...),
		Nonce:        append([]byte(nil), env.Nonce...),
		CreatedAt:    now,
	}
	s.db.KeyEnvelopes[out.ID] = out
	s.markDirty()
	return cloneKeyEnvelope(out), nil
}

// ListKeyEnvelopes returns the envelopes addressed to one device.
func (s *Store) ListKeyEnvelopes(recipientID, conversationID string, since time.Time) []*KeyEnvelope {
	s.mu.RLock()
	defer s.mu.RUnlock()
	var out []*KeyEnvelope
	for _, env := range s.db.KeyEnvelopes {
		if env.RecipientID != recipientID {
			continue
		}
		if conversationID != "" && env.Conversation != conversationID {
			continue
		}
		if !since.IsZero() && !env.CreatedAt.After(since) {
			continue
		}
		out = append(out, cloneKeyEnvelope(env))
	}
	sort.Slice(out, func(i, j int) bool { return out[i].CreatedAt.After(out[j].CreatedAt) })
	return out
}

// CountKeyEnvelopes is used by tests and diagnostics.
func (s *Store) CountKeyEnvelopes() int {
	s.mu.RLock()
	defer s.mu.RUnlock()
	return len(s.db.KeyEnvelopes)
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
