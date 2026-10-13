package httpserver_test

import (
	"bytes"
	"context"
	"testing"

	"connectrpc.com/connect"

	ratatoskv1 "github.com/gokr/ratatosk/server/gen/ratatosk/v1"
	"github.com/gokr/ratatosk/server/gen/ratatosk/v1/ratatoskv1connect"
)

func sampleBackup(blob []byte) *ratatoskv1.KeyBackup {
	return &ratatoskv1.KeyBackup{
		Salt:        bytes.Repeat([]byte{1}, 16),
		Nonce:       bytes.Repeat([]byte{2}, 24),
		Blob:        blob,
		Kdf:         "argon2id",
		MemoryKib:   64 * 1024,
		Iterations:  3,
		Parallelism: 2,
		Version:     "ratatosk/keys/v1",
	}
}

// The key backup through the wire: the two properties a client depends on are that
// an account only ever gets its own, and that the server hands back exactly what it
// was given — a backup that comes back altered cannot be opened.
func TestKeyBackupThroughTheAPI(t *testing.T) {
	h := newHarness(t)
	ctx := context.Background()
	auth := ratatoskv1connect.NewAuthServiceClient(h.srv.Client(), h.baseURL)

	register := func(username string) string {
		res, err := auth.Register(ctx, connect.NewRequest(&ratatoskv1.RegisterRequest{
			Username: username, Password: "correct horse battery", DisplayName: username,
		}))
		if err != nil {
			t.Fatalf("register %s: %v", username, err)
		}
		return res.Msg.GetToken()
	}
	adaToken := register("ada")
	graceToken := register("grace")
	keys := func(token string) ratatoskv1connect.KeyServiceClient {
		return ratatoskv1connect.NewKeyServiceClient(h.srv.Client(), h.baseURL,
			connect.WithInterceptors(bearerInterceptor{token: token}))
	}
	ada, grace := keys(adaToken), keys(graceToken)

	// Nobody has a backup yet, and that is not an error.
	none, err := ada.GetKeyBackup(ctx, connect.NewRequest(&ratatoskv1.GetKeyBackupRequest{}))
	if err != nil {
		t.Fatalf("get with no backup: %v", err)
	}
	if none.Msg.GetBackup() != nil {
		t.Fatal("an account with no backup got one")
	}

	// Round-trip, byte for byte.
	blob := []byte("sealed key material, unreadable here")
	if _, err := ada.PutKeyBackup(ctx, connect.NewRequest(&ratatoskv1.PutKeyBackupRequest{Backup: sampleBackup(blob)})); err != nil {
		t.Fatalf("put: %v", err)
	}
	got, err := ada.GetKeyBackup(ctx, connect.NewRequest(&ratatoskv1.GetKeyBackupRequest{}))
	if err != nil {
		t.Fatalf("get: %v", err)
	}
	if !bytes.Equal(got.Msg.GetBackup().GetBlob(), blob) {
		t.Errorf("blob = %q, want %q", got.Msg.GetBackup().GetBlob(), blob)
	}
	if got.Msg.GetBackup().GetKdf() != "argon2id" || got.Msg.GetBackup().GetVersion() != "ratatosk/keys/v1" {
		t.Errorf("kdf parameters lost in transit: %+v", got.Msg.GetBackup())
	}

	// Grace must not see it: the blob is useless without the passphrase, but it is
	// still an encrypted bundle of somebody else's keys.
	other, err := grace.GetKeyBackup(ctx, connect.NewRequest(&ratatoskv1.GetKeyBackupRequest{}))
	if err != nil {
		t.Fatalf("grace get: %v", err)
	}
	if other.Msg.GetBackup() != nil {
		t.Error("one account could read another's backup")
	}

	// A malformed backup is refused rather than stored, so a client bug surfaces
	// now instead of on the day the backup is needed.
	bad := sampleBackup(blob)
	bad.MemoryKib = 4 * 1024 * 1024
	if _, err := ada.PutKeyBackup(ctx, connect.NewRequest(&ratatoskv1.PutKeyBackupRequest{Backup: bad})); codeOf(err) != connect.CodeInvalidArgument {
		t.Errorf("absurd kdf parameters: code = %v, want InvalidArgument", codeOf(err))
	}

	// Unauthenticated callers get nothing.
	anon := ratatoskv1connect.NewKeyServiceClient(h.srv.Client(), h.baseURL)
	if _, err := anon.GetKeyBackup(ctx, connect.NewRequest(&ratatoskv1.GetKeyBackupRequest{})); codeOf(err) != connect.CodeUnauthenticated {
		t.Errorf("anonymous get: code = %v, want Unauthenticated", codeOf(err))
	}

	// Deleting is idempotent, and the backup is really gone.
	for i := 0; i < 2; i++ {
		if _, err := ada.DeleteKeyBackup(ctx, connect.NewRequest(&ratatoskv1.DeleteKeyBackupRequest{})); err != nil {
			t.Fatalf("delete #%d: %v", i+1, err)
		}
	}
	after, err := ada.GetKeyBackup(ctx, connect.NewRequest(&ratatoskv1.GetKeyBackupRequest{}))
	if err != nil {
		t.Fatalf("get after delete: %v", err)
	}
	if after.Msg.GetBackup() != nil {
		t.Error("the backup survived deletion")
	}
}
