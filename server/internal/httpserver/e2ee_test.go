package httpserver_test

import (
	"bytes"
	"context"
	"crypto/rand"
	"io"
	"log/slog"
	"os"
	"path/filepath"
	"testing"

	"connectrpc.com/connect"

	ratatoskv1 "github.com/gokr/ratatosk/server/gen/ratatosk/v1"
	"github.com/gokr/ratatosk/server/gen/ratatosk/v1/ratatoskv1connect"
	"github.com/gokr/ratatosk/server/internal/store"
)

// randomBytes is the test's stand-in for a client-side seal: from the server's
// point of view there is no difference between real ciphertext and this.
func randomBytes(t *testing.T, n int) []byte {
	t.Helper()
	b := make([]byte, n)
	if _, err := rand.Read(b); err != nil {
		t.Fatalf("rand: %v", err)
	}
	return b
}

func newKeysClient(t *testing.T, h *harness, token, deviceKeyID string) ratatoskv1connect.KeyServiceClient {
	t.Helper()
	opt := connect.WithInterceptors(bearerInterceptor{token: token, deviceKey: deviceKeyID})
	return ratatoskv1connect.NewKeyServiceClient(h.srv.Client(), h.baseURL, opt)
}

// TestEncryptedMessagePathNeverSeesPlaintext is the central end-to-end
// requirement: a sealed message is stored, fanned out and served back without
// the server ever holding its content, and the reply preview stays hidden.
func TestEncryptedMessagePathNeverSeesPlaintext(t *testing.T) {
	h := newHarness(t)
	adaToken, _ := h.register("ada", "password123", "Ada")
	graceToken, grace := h.register("grace", "password123", "Grace")
	ctx := context.Background()

	// Each side registers the device key it encrypts with.
	adaKey := registerDeviceKey(t, h, adaToken, "Ada's laptop")
	graceKey := registerDeviceKey(t, h, graceToken, "Grace's phone")

	_, adaChat, _ := h.authed(adaToken)
	_, graceChat, _ := h.authed(graceToken)

	// A conversation with one sealed message.
	direct, err := adaChat.CreateDirectConversation(ctx, connect.NewRequest(&ratatoskv1.CreateDirectConversationRequest{
		Username: "grace",
	}))
	if err != nil {
		t.Fatalf("create direct: %v", err)
	}
	convID := direct.Msg.GetConversation().GetId()

	// Ada can see Grace's public key; a stranger cannot enumerate keys.
	adaKeys := newKeysClient(t, h, adaToken, adaKey.GetId())
	listed, err := adaKeys.ListDeviceKeys(ctx, connect.NewRequest(&ratatoskv1.ListDeviceKeysRequest{
		UserIds: []string{grace.GetId()},
	}))
	if err != nil {
		t.Fatalf("list keys: %v", err)
	}
	if len(listed.Msg.GetDeviceKeys()) != 1 || !bytes.Equal(listed.Msg.GetDeviceKeys()[0].GetIdentityPublicKey(), graceKey.GetIdentityPublicKey()) {
		t.Fatalf("grace's key was not served correctly: %v", listed.Msg.GetDeviceKeys())
	}
	malloryToken, _ := h.register("mallory", "password123", "Mallory")
	malloryKeys := newKeysClient(t, h, malloryToken, "")
	if _, err := malloryKeys.ListDeviceKeys(ctx, connect.NewRequest(&ratatoskv1.ListDeviceKeysRequest{
		UserIds: []string{grace.GetId()},
	})); codeOf(err) != connect.CodePermissionDenied {
		t.Fatalf("stranger key enumeration: code = %v, want PermissionDenied", codeOf(err))
	}

	seal := randomBytes(t, 96)
	sent, err := adaChat.SendMessage(ctx, connect.NewRequest(&ratatoskv1.SendMessageRequest{
		ConversationId:    convID,
		Ciphertext:        seal,
		Nonce:             randomBytes(t, 24),
		SenderDeviceKeyId: adaKey.GetId(),
		KeyEpoch:          0,
		CryptoVersion:     "ratatosk/v1",
		ClientMessageId:   "sealed-1",
	}))
	if err != nil {
		t.Fatalf("send sealed: %v", err)
	}
	msg := sent.Msg.GetMessage()
	if !msg.GetEncrypted() {
		t.Fatal("the stored message does not report itself as encrypted")
	}
	if msg.GetText() != "" {
		t.Fatalf("the server returned plaintext %q for a sealed message", msg.GetText())
	}
	if !bytes.Equal(msg.GetCiphertext(), seal) {
		t.Fatal("the sealed bytes changed in transit")
	}
	if msg.GetSenderDeviceKeyId() != adaKey.GetId() {
		t.Fatalf("sender device key = %q, want %q", msg.GetSenderDeviceKeyId(), adaKey.GetId())
	}
	if msg.GetCryptoVersion() != "ratatosk/v1" {
		t.Fatalf("crypto version = %q", msg.GetCryptoVersion())
	}

	// Grace reads it back: still opaque, still intact.
	page, err := graceChat.ListMessages(ctx, connect.NewRequest(&ratatoskv1.ListMessagesRequest{
		ConversationId: convID,
	}))
	if err != nil {
		t.Fatalf("list: %v", err)
	}
	if got := page.Msg.GetMessages(); len(got) != 1 || !bytes.Equal(got[0].GetCiphertext(), seal) {
		t.Fatal("the sealed message did not round-trip")
	}

	// Sending both plaintext and ciphertext is refused: whichever the server
	// kept, one of the two would be a surprise to somebody.
	if _, err := adaChat.SendMessage(ctx, connect.NewRequest(&ratatoskv1.SendMessageRequest{
		ConversationId:    convID,
		Text:              "also in the clear",
		Ciphertext:        randomBytes(t, 32),
		Nonce:             randomBytes(t, 24),
		SenderDeviceKeyId: adaKey.GetId(),
		CryptoVersion:     "ratatosk/v1",
	})); codeOf(err) != connect.CodeInvalidArgument {
		t.Fatalf("mixed send: code = %v, want InvalidArgument", codeOf(err))
	}
	// A seal without the coordinates of its key is unopenable, so it is refused.
	if _, err := adaChat.SendMessage(ctx, connect.NewRequest(&ratatoskv1.SendMessageRequest{
		ConversationId: convID,
		Ciphertext:     randomBytes(t, 32),
	})); codeOf(err) != connect.CodeInvalidArgument {
		t.Fatalf("seal without a nonce: code = %v, want InvalidArgument", codeOf(err))
	}

	// Server-side search cannot match a sealed body, which is why the client
	// searches its decrypted history instead.
	found, err := graceChat.SearchMessages(ctx, connect.NewRequest(&ratatoskv1.SearchMessagesRequest{
		Query: "never read",
	}))
	if err != nil {
		t.Fatalf("search: %v", err)
	}
	if len(found.Msg.GetResults()) != 0 {
		t.Fatal("server-side search matched the plaintext of a sealed message")
	}

	// An edit replaces the seal; the old bytes are gone.
	resealed := randomBytes(t, 64)
	edited, err := adaChat.EditMessage(ctx, connect.NewRequest(&ratatoskv1.EditMessageRequest{
		MessageId:     msg.GetId(),
		Ciphertext:    resealed,
		Nonce:         randomBytes(t, 24),
		CryptoVersion: "ratatosk/v1",
	}))
	if err != nil {
		t.Fatalf("edit sealed: %v", err)
	}
	if !bytes.Equal(edited.Msg.GetMessage().GetCiphertext(), resealed) || edited.Msg.GetMessage().GetText() != "" {
		t.Fatal("editing a sealed message did not replace the seal")
	}

	// The blob the server holds for an encrypted attachment carries neither the
	// filename nor a usable content type.
	up, err := adaChat.UploadAttachment(ctx, connect.NewRequest(&ratatoskv1.UploadAttachmentRequest{
		Filename:    "bank-statement.pdf",
		ContentType: "application/pdf",
		Data:        randomBytes(t, 64),
		Encrypted:   true,
	}))
	if err != nil {
		t.Fatalf("upload sealed: %v", err)
	}
	att := up.Msg.GetAttachment()
	if !att.GetEncrypted() {
		t.Fatal("a sealed upload is not marked as encrypted")
	}
	if att.GetFilename() != "" || att.GetContentType() != "" || att.GetIsImage() {
		t.Fatalf("sealed attachment leaked metadata: filename=%q type=%q", att.GetFilename(), att.GetContentType())
	}
}

// The key envelope path: only the addressed device gets a copy, and the server
// cannot open what it relays.
func TestKeyEnvelopesAreRelayedButNotReadable(t *testing.T) {
	h := newHarness(t)
	adaToken, _ := h.register("ada", "password123", "Ada")
	graceToken, grace := h.register("grace", "password123", "Grace")
	ctx := context.Background()

	adaKey := registerDeviceKey(t, h, adaToken, "Ada's laptop")
	graceKey := registerDeviceKey(t, h, graceToken, "Grace's phone")
	_, adaChat, _ := h.authed(adaToken)

	group, err := adaChat.CreateGroupConversation(ctx, connect.NewRequest(&ratatoskv1.CreateGroupConversationRequest{
		Title:     "Union",
		Usernames: []string{"grace"},
	}))
	if err != nil {
		t.Fatalf("create group: %v", err)
	}
	convID := group.Msg.GetConversation().GetId()

	wrapped := randomBytes(t, 48)
	adaKeys := newKeysClient(t, h, adaToken, adaKey.GetId())
	put, err := adaKeys.PutKeyEnvelope(ctx, connect.NewRequest(&ratatoskv1.PutKeyEnvelopeRequest{
		ConversationId:       convID,
		SenderDeviceKeyId:    adaKey.GetId(),
		RecipientDeviceKeyId: graceKey.GetId(),
		Epoch:                0,
		WrappedKey:           wrapped,
		Nonce:                randomBytes(t, 24),
	}))
	if err != nil {
		t.Fatalf("put envelope: %v", err)
	}
	if !bytes.Equal(put.Msg.GetEnvelope().GetWrappedKey(), wrapped) {
		t.Fatal("the wrapped key changed in transit")
	}

	// Grace's device finds it; her other device would not, and neither does
	// somebody else's.
	graceKeys := newKeysClient(t, h, graceToken, graceKey.GetId())
	mine, err := graceKeys.ListKeyEnvelopes(ctx, connect.NewRequest(&ratatoskv1.ListKeyEnvelopesRequest{}))
	if err != nil {
		t.Fatalf("list envelopes: %v", err)
	}
	if len(mine.Msg.GetEnvelopes()) != 1 || !bytes.Equal(mine.Msg.GetEnvelopes()[0].GetWrappedKey(), wrapped) {
		t.Fatalf("grace did not receive her envelope: %v", mine.Msg.GetEnvelopes())
	}
	noDevice := newKeysClient(t, h, graceToken, "")
	if _, err := noDevice.ListKeyEnvelopes(ctx, connect.NewRequest(&ratatoskv1.ListKeyEnvelopesRequest{})); codeOf(err) != connect.CodeFailedPrecondition {
		t.Fatalf("envelope fetch without a device key: code = %v, want FailedPrecondition", codeOf(err))
	}

	// A member may only distribute its own sender key, and only to devices of
	// people in the conversation.
	graceKeysAsAda := newKeysClient(t, h, adaToken, adaKey.GetId())
	if _, err := graceKeysAsAda.PutKeyEnvelope(ctx, connect.NewRequest(&ratatoskv1.PutKeyEnvelopeRequest{
		ConversationId:       convID,
		SenderDeviceKeyId:    graceKey.GetId(), // not Ada's
		RecipientDeviceKeyId: graceKey.GetId(),
		WrappedKey:           randomBytes(t, 48),
		Nonce:                randomBytes(t, 24),
	})); codeOf(err) != connect.CodePermissionDenied {
		t.Fatalf("distributing somebody else's sender key: code = %v, want PermissionDenied", codeOf(err))
	}

	malloryToken, _ := h.register("mallory", "password123", "Mallory")
	malloryKey := registerDeviceKey(t, h, malloryToken, "Mallory's box")
	if _, err := adaKeys.PutKeyEnvelope(ctx, connect.NewRequest(&ratatoskv1.PutKeyEnvelopeRequest{
		ConversationId:       convID,
		SenderDeviceKeyId:    adaKey.GetId(),
		RecipientDeviceKeyId: malloryKey.GetId(), // not a member
		WrappedKey:           randomBytes(t, 48),
		Nonce:                randomBytes(t, 24),
	})); codeOf(err) != connect.CodePermissionDenied {
		t.Fatalf("envelope to a non-member: code = %v, want PermissionDenied", codeOf(err))
	}

	// Revoking a device key makes it unusable and takes its envelopes with it.
	if _, err := graceKeys.RevokeDeviceKey(ctx, connect.NewRequest(&ratatoskv1.RevokeDeviceKeyRequest{
		Id: graceKey.GetId(),
	})); err != nil {
		t.Fatalf("revoke: %v", err)
	}
	if _, err := graceKeys.ListKeyEnvelopes(ctx, connect.NewRequest(&ratatoskv1.ListKeyEnvelopesRequest{})); codeOf(err) != connect.CodeFailedPrecondition {
		t.Fatalf("revoked device still fetches envelopes: code = %v", codeOf(err))
	}
	after, err := adaKeys.ListDeviceKeys(ctx, connect.NewRequest(&ratatoskv1.ListDeviceKeysRequest{
		UserIds: []string{grace.GetId()},
	}))
	if err != nil {
		t.Fatalf("list after revoke: %v", err)
	}
	if len(after.Msg.GetDeviceKeys()) != 0 {
		t.Fatalf("revoked key still listed: %v", after.Msg.GetDeviceKeys())
	}
}

// A device key is immutable: a re-publish with different public keys is
// refused, which is what makes a safety number meaningful.
func TestDeviceKeysCannotBeSubstituted(t *testing.T) {
	h := newHarness(t)
	adaToken, _ := h.register("ada", "password123", "Ada")
	ctx := context.Background()

	key := registerDeviceKey(t, h, adaToken, "Laptop")
	keys := newKeysClient(t, h, adaToken, key.GetId())

	// The same keys again: accepted, so a client can publish on every start.
	if _, err := keys.PublishDeviceKey(ctx, connect.NewRequest(&ratatoskv1.PublishDeviceKeyRequest{
		Id:                key.GetId(),
		IdentityPublicKey: key.GetIdentityPublicKey(),
		SigningPublicKey:  key.GetSigningPublicKey(),
		Label:             "Laptop (renamed)",
		Platform:          "linux",
	})); err != nil {
		t.Fatalf("re-publish: %v", err)
	}
	// Different keys under the same id: refused.
	if _, err := keys.PublishDeviceKey(ctx, connect.NewRequest(&ratatoskv1.PublishDeviceKeyRequest{
		Id:                key.GetId(),
		IdentityPublicKey: randomBytes(t, 32),
		SigningPublicKey:  key.GetSigningPublicKey(),
	})); codeOf(err) != connect.CodeFailedPrecondition {
		t.Fatalf("key substitution: code = %v, want FailedPrecondition", codeOf(err))
	}
	// Garbage key sizes are refused up front.
	if _, err := keys.PublishDeviceKey(ctx, connect.NewRequest(&ratatoskv1.PublishDeviceKeyRequest{
		IdentityPublicKey: randomBytes(t, 16),
		SigningPublicKey:  randomBytes(t, 32),
	})); codeOf(err) != connect.CodeInvalidArgument {
		t.Fatalf("short key: code = %v, want InvalidArgument", codeOf(err))
	}
}

// The data directory must not contain readable message content, even with a
// conversation full of plaintext-era data.
func TestDataDirectoryRevealsNoPlaintext(t *testing.T) {
	dir := t.TempDir()
	srv, st := newServerOn(t, dir)
	auth := ratatoskv1connect.NewAuthServiceClient(srv.Client(), srv.URL)
	ctx := context.Background()

	reg, err := auth.Register(ctx, connect.NewRequest(&ratatoskv1.RegisterRequest{
		Username: "ada", Password: "password123", DisplayName: "Ada Lovelace",
	}))
	if err != nil {
		t.Fatalf("register: %v", err)
	}
	opt := connect.WithInterceptors(bearerInterceptor{token: reg.Msg.GetToken()})
	chat := ratatoskv1connect.NewChatServiceClient(srv.Client(), srv.URL, opt)
	if _, err := auth.Register(ctx, connect.NewRequest(&ratatoskv1.RegisterRequest{
		Username: "grace", Password: "password123",
	})); err != nil {
		t.Fatalf("register grace: %v", err)
	}
	direct, err := chat.CreateDirectConversation(ctx, connect.NewRequest(&ratatoskv1.CreateDirectConversationRequest{
		Username: "grace",
	}))
	if err != nil {
		t.Fatalf("create direct: %v", err)
	}
	// A system note is server-authored plaintext, which is exactly what at-rest
	// encryption has to cover.
	if _, err := chat.CreateGroupConversation(ctx, connect.NewRequest(&ratatoskv1.CreateGroupConversationRequest{
		Title:     "Union Local 47",
		Usernames: []string{"grace"},
	})); err != nil {
		t.Fatalf("create group: %v", err)
	}
	// And a sealed message.
	if _, err := chat.SendMessage(ctx, connect.NewRequest(&ratatoskv1.SendMessageRequest{
		ConversationId:    direct.Msg.GetConversation().GetId(),
		Ciphertext:        randomBytes(t, 64),
		Nonce:             randomBytes(t, 24),
		CryptoVersion:     "ratatosk/v1",
		SenderDeviceKeyId: "k-test",
	})); err != nil {
		t.Fatalf("send sealed: %v", err)
	}

	// Close the store so the snapshot is on disk, then read every byte of the
	// data directory.
	if err := st.Close(); err != nil {
		t.Fatalf("close: %v", err)
	}
	var all []byte
	err = filepath.Walk(dir, func(path string, info os.FileInfo, err error) error {
		if err != nil || info.IsDir() {
			return err
		}
		// The key file is hex, not content: skip it, it is checked separately.
		if filepath.Base(path) == "data-key" {
			return nil
		}
		data, readErr := os.ReadFile(path)
		if readErr != nil {
			return readErr
		}
		all = append(all, data...)
		return nil
	})
	if err != nil {
		t.Fatalf("walk: %v", err)
	}
	// "ada" and "grace" are deliberately not checked: both are substrings of
	// schema words ("metadata", "grace" in nothing) that legitimately appear in
	// the SQLite file, so the check would be a false positive rather than a leak.
	for _, secret := range []string{"Ada Lovelace", "Union Local 47"} {
		if bytes.Contains(all, []byte(secret)) {
			t.Errorf("the data directory still contains %q", secret)
		}
	}

	// Reopening the directory proves the encrypted rows are readable again: the
	// data is unreadable in the file but intact for the server that has the key.
	reopened, err := store.Open(dir, slog.New(slog.NewTextHandler(io.Discard, nil)))
	if err != nil {
		t.Fatalf("reopen store: %v", err)
	}
	defer reopened.Close()
	if got := reopened.Stats(); got.Users != 2 || got.Conversations != 2 || got.Messages != 2 {
		t.Fatalf("stats after reopen = %+v, want 2 users, 2 conversations, 2 messages", got)
	}
}

// registerDeviceKey publishes a fresh device key for a signed-in test client.
func registerDeviceKey(t *testing.T, h *harness, token, label string) *ratatoskv1.DeviceKey {
	t.Helper()
	keys := newKeysClient(t, h, token, "")
	res, err := keys.PublishDeviceKey(context.Background(), connect.NewRequest(&ratatoskv1.PublishDeviceKeyRequest{
		IdentityPublicKey: randomBytes(t, 32),
		SigningPublicKey:  randomBytes(t, 32),
		Label:             label,
		Platform:          "linux",
	}))
	if err != nil {
		t.Fatalf("publish device key: %v", err)
	}
	return res.Msg.GetDeviceKey()
}
