package service

import (
	"context"
	"time"

	"connectrpc.com/connect"

	ratatoskv1 "github.com/gokr/ratatosk/server/gen/ratatosk/v1"
	"github.com/gokr/ratatosk/server/internal/auth"
	"github.com/gokr/ratatosk/server/internal/store"
)

// KeyService implements ratatosk.v1.KeyService: the public key directory and
// the mailbox for sealed sender keys.
//
// Three rules shape every handler here:
//
//   - The server never sees a private key, so it can only ever act on public
//     material and opaque blobs.
//   - Key material is immutable. Publishing a different public key under an
//     existing device key id is refused rather than silently accepted, because
//     a device key that can change under a recorded safety number is a
//     substitution attack with extra steps.
//   - Envelopes are only accepted between devices that are both in the
//     conversation, so the service cannot be used as a blind relay.
type KeyService struct {
	*base
}

// NewKeyService wires the key service onto the shared state.
func NewKeyService(b *base) *KeyService { return &KeyService{base: b} }

func (s *KeyService) PublishDeviceKey(ctx context.Context, req *connect.Request[ratatoskv1.PublishDeviceKeyRequest]) (*connect.Response[ratatoskv1.PublishDeviceKeyResponse], error) {
	user, err := s.requireUser(ctx)
	if err != nil {
		return nil, err
	}
	identity := req.Msg.GetIdentityPublicKey()
	signing := req.Msg.GetSigningPublicKey()
	if len(identity) != 32 {
		return nil, connect.NewError(connect.CodeInvalidArgument, errInvalid("the identity public key must be 32 bytes (X25519)"))
	}
	if len(signing) != 32 {
		return nil, connect.NewError(connect.CodeInvalidArgument, errInvalid("the signing public key must be 32 bytes (Ed25519)"))
	}

	label := trimSpace(req.Msg.GetLabel())
	if len(label) > 64 {
		label = label[:64]
	}
	platform := trimSpace(req.Msg.GetPlatform())
	if len(platform) > 32 {
		platform = platform[:32]
	}

	key, err := s.st.PublishDeviceKey(req.Msg.GetId(), user.ID, identity, signing, label, platform, now())
	switch {
	case err == store.ErrInvalidKey:
		// Either the key material is malformed, or the caller tried to change
		// an existing device key's public keys.
		return nil, connect.NewError(connect.CodeFailedPrecondition,
			errInvalid("a published device key cannot change its public keys; publish a new device key instead"))
	case err == store.ErrNotFound:
		return nil, connect.NewError(connect.CodeNotFound, errInvalid("unknown device key"))
	case err != nil:
		return nil, connect.NewError(connect.CodeInternal, err)
	}
	return connect.NewResponse(&ratatoskv1.PublishDeviceKeyResponse{DeviceKey: deviceKeyProto(key)}), nil
}

func (s *KeyService) ListDeviceKeys(ctx context.Context, req *connect.Request[ratatoskv1.ListDeviceKeysRequest]) (*connect.Response[ratatoskv1.ListDeviceKeysResponse], error) {
	user, err := s.requireUser(ctx)
	if err != nil {
		return nil, err
	}
	// Only keys of people the caller can actually talk to. Presence and the
	// account search already expose handles; a full key dump would additionally
	// expose every device of every user, which is more than needed to encrypt.
	allowed := map[string]struct{}{user.ID: {}}
	for _, id := range s.contactsFor(user.ID) {
		allowed[id] = struct{}{}
	}

	wanted := req.Msg.GetUserIds()
	if len(wanted) == 0 {
		wanted = []string{user.ID}
	}
	var keys []*store.DeviceKey
	for _, id := range wanted {
		if _, ok := allowed[id]; !ok {
			return nil, connect.NewError(connect.CodePermissionDenied,
				errInvalid("you can only fetch the device keys of your contacts and conversation partners"))
		}
		keys = append(keys, s.st.DeviceKeysOf(id, req.Msg.GetIncludeRevoked())...)
	}

	out := make([]*ratatoskv1.DeviceKey, 0, len(keys))
	for _, key := range keys {
		out = append(out, deviceKeyProto(key))
	}
	return connect.NewResponse(&ratatoskv1.ListDeviceKeysResponse{DeviceKeys: out}), nil
}

func (s *KeyService) RevokeDeviceKey(ctx context.Context, req *connect.Request[ratatoskv1.RevokeDeviceKeyRequest]) (*connect.Response[ratatoskv1.RevokeDeviceKeyResponse], error) {
	user, err := s.requireUser(ctx)
	if err != nil {
		return nil, err
	}
	if err := s.st.RevokeDeviceKey(req.Msg.GetId(), user.ID); err != nil {
		return nil, connect.NewError(connect.CodeNotFound, errInvalid("unknown device key"))
	}
	s.log.Info("device key revoked", "user", user.ID, "device", req.Msg.GetId())
	return connect.NewResponse(&ratatoskv1.RevokeDeviceKeyResponse{}), nil
}

func (s *KeyService) PutKeyEnvelope(ctx context.Context, req *connect.Request[ratatoskv1.PutKeyEnvelopeRequest]) (*connect.Response[ratatoskv1.PutKeyEnvelopeResponse], error) {
	user, err := s.requireUser(ctx)
	if err != nil {
		return nil, err
	}
	convID := req.Msg.GetConversationId()
	if _, _, err := s.requireMember(ctx, convID); err != nil {
		return nil, err
	}

	senderKey, err := s.st.DeviceKeyByID(req.Msg.GetSenderDeviceKeyId())
	if err != nil || senderKey.UserID != user.ID {
		// A device may only distribute its own sender key.
		return nil, connect.NewError(connect.CodePermissionDenied, errInvalid("you can only distribute your own sender key"))
	}
	if req.Msg.GetEpoch() < 0 {
		return nil, connect.NewError(connect.CodeInvalidArgument, errInvalid("epoch must not be negative"))
	}

	envelope, err := s.st.PutKeyEnvelope(&store.KeyEnvelope{
		Conversation: convID,
		SenderKeyID:  req.Msg.GetSenderDeviceKeyId(),
		RecipientID:  req.Msg.GetRecipientDeviceKeyId(),
		Epoch:        req.Msg.GetEpoch(),
		Wrapped:      req.Msg.GetWrappedKey(),
		Nonce:        req.Msg.GetNonce(),
	}, now())
	switch {
	case err == store.ErrInvalidKey:
		return nil, connect.NewError(connect.CodeInvalidArgument,
			errInvalid("the wrapped sender key or its nonce is the wrong size"))
	case err == store.ErrNotMember:
		return nil, connect.NewError(connect.CodePermissionDenied,
			errInvalid("both devices must belong to members of this conversation"))
	case err != nil:
		return nil, connect.NewError(connect.CodeNotFound, errInvalid("unknown conversation or device key"))
	}

	// Nothing is pushed to the recipient: a key envelope is useless until a
	// message arrives that references it, and the client fetches envelopes
	// before decrypting. Pushing here would leak key-distribution timing to the
	// server's own hub and buy the client nothing.
	return connect.NewResponse(&ratatoskv1.PutKeyEnvelopeResponse{Envelope: envelopeProto(envelope)}), nil
}

func (s *KeyService) ListKeyEnvelopes(ctx context.Context, req *connect.Request[ratatoskv1.ListKeyEnvelopesRequest]) (*connect.Response[ratatoskv1.ListKeyEnvelopesResponse], error) {
	user, err := s.requireUser(ctx)
	if err != nil {
		return nil, err
	}
	deviceID := auth.DeviceKeyFrom(ctx)
	if deviceID == "" {
		return nil, connect.NewError(connect.CodeFailedPrecondition,
			errInvalid("publish a device key before fetching sender keys"))
	}
	if convID := req.Msg.GetConversationId(); convID != "" {
		if _, _, err := s.requireMember(ctx, convID); err != nil {
			return nil, err
		}
	}
	var since time.Time
	if req.Msg.GetSince() != nil {
		since = req.Msg.GetSince().AsTime()
	}
	envelopes := s.st.ListKeyEnvelopes(deviceID, req.Msg.GetConversationId(), since)
	out := make([]*ratatoskv1.KeyEnvelope, 0, len(envelopes))
	for _, envelope := range envelopes {
		out = append(out, envelopeProto(envelope))
	}
	_ = user
	return connect.NewResponse(&ratatoskv1.ListKeyEnvelopesResponse{Envelopes: out}), nil
}

// --- conversions ---------------------------------------------------------

func deviceKeyProto(k *store.DeviceKey) *ratatoskv1.DeviceKey {
	if k == nil {
		return nil
	}
	return &ratatoskv1.DeviceKey{
		Id:                 k.ID,
		UserId:             k.UserID,
		IdentityPublicKey:  k.Identity,
		SigningPublicKey:   k.Signing,
		Label:              k.Label,
		Platform:           k.Platform,
		CreatedAt:          ts(k.CreatedAt),
		LastSeen:           ts(k.LastSeen),
		Fingerprint:        k.Fingerprint(),
		Revoked:            k.Revoked,
	}
}

func envelopeProto(e *store.KeyEnvelope) *ratatoskv1.KeyEnvelope {
	if e == nil {
		return nil
	}
	return &ratatoskv1.KeyEnvelope{
		Id:                   e.ID,
		ConversationId:       e.Conversation,
		SenderDeviceKeyId:    e.SenderKeyID,
		RecipientDeviceKeyId: e.RecipientID,
		Epoch:                e.Epoch,
		WrappedKey:           e.Wrapped,
		Nonce:                e.Nonce,
		CreatedAt:            ts(e.CreatedAt),
	}
}
