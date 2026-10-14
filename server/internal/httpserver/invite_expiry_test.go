package httpserver_test

import (
	"context"
	"testing"
	"time"

	"connectrpc.com/connect"

	ratatoskv1 "github.com/gokr/ratatosk/server/gen/ratatosk/v1"
)

// Invite expiry, because "most of them seem already expired" is a claim the server
// should be able to answer: either the arithmetic is right or it is not.
func TestInviteExpiryArithmetic(t *testing.T) {
	h := newHarness(t)
	ctx := context.Background()
	token, _ := h.register("ada", "password123", "Ada")
	_, _, social := h.authed(token)

	// The default the client sends is a week; it must be a week out, not in the past.
	week, err := social.CreateInvite(ctx, connect.NewRequest(&ratatoskv1.CreateInviteRequest{
		ExpiresInHours: 24 * 7, MaxUses: 1,
	}))
	if err != nil {
		t.Fatalf("create: %v", err)
	}
	inv := week.Msg.GetInvite()
	if !inv.GetValid() {
		t.Fatalf("a freshly created invite is already invalid: %q", inv.GetInvalidReason())
	}
	if inv.GetExpiresAt() == nil {
		t.Fatal("a week-long invite has no expiry")
	}
	remaining := time.Until(inv.GetExpiresAt().AsTime())
	if remaining < 24*6*time.Hour || remaining > 24*8*time.Hour {
		t.Fatalf("a week-long invite expires in %v", remaining)
	}
	if inv.GetInvalidReason() != "" {
		t.Errorf("a valid invite carries a reason: %q", inv.GetInvalidReason())
	}

	// An hour is an hour, and it is usable.
	hour, err := social.CreateInvite(ctx, connect.NewRequest(&ratatoskv1.CreateInviteRequest{
		ExpiresInHours: 1, MaxUses: 1,
	}))
	if err != nil {
		t.Fatalf("create: %v", err)
	}
	if !hour.Msg.GetInvite().GetValid() {
		t.Error("a one-hour invite is not valid")
	}

	// Never expires is expressible and stays valid.
	never, err := social.CreateInvite(ctx, connect.NewRequest(&ratatoskv1.CreateInviteRequest{
		ExpiresInHours: -1, MaxUses: -1,
	}))
	if err != nil {
		t.Fatalf("create: %v", err)
	}
	if never.Msg.GetInvite().GetExpiresAt() != nil {
		t.Error("an invite that should never expire has an expiry")
	}
	if !never.Msg.GetInvite().GetValid() {
		t.Error("an invite with no expiry is not valid")
	}

	// A list of fresh invites must be all-valid: the reported symptom was that most
	// were expired, and if that were real it would show here.
	list, err := social.ListInvites(ctx, connect.NewRequest(&ratatoskv1.ListInvitesRequest{}))
	if err != nil {
		t.Fatalf("list: %v", err)
	}
	for _, item := range list.Msg.GetInvites() {
		if !item.GetValid() {
			t.Errorf("fresh invite %s is listed as invalid (%q)", item.GetCode(), item.GetInvalidReason())
		}
	}

	// An expiresInHours far beyond the cap is refused rather than silently clamped,
	// so a client cannot create something it did not ask for.
	if _, err := social.CreateInvite(ctx, connect.NewRequest(&ratatoskv1.CreateInviteRequest{
		ExpiresInHours: 24 * 400,
	})); codeOf(err) != connect.CodeInvalidArgument {
		t.Errorf("an absurd expiry: code = %v, want InvalidArgument", codeOf(err))
	}
}

// The reason reported for a dead invite is what the list shows, so it has to be one of
// the vocabulary the client understands rather than a free-text sentence.
func TestInviteInvalidReasonVocabulary(t *testing.T) {
	h := newHarness(t)
	ctx := context.Background()
	token, _ := h.register("ada", "password123", "Ada")
	_, _, social := h.authed(token)

	created, err := social.CreateInvite(ctx, connect.NewRequest(&ratatoskv1.CreateInviteRequest{
		ExpiresInHours: 24, MaxUses: 1,
	}))
	if err != nil {
		t.Fatalf("create: %v", err)
	}
	code := created.Msg.GetInvite().GetCode()

	if _, err := social.RevokeInvite(ctx, connect.NewRequest(&ratatoskv1.RevokeInviteRequest{Code: code})); err != nil {
		t.Fatalf("revoke: %v", err)
	}
	list, err := social.ListInvites(ctx, connect.NewRequest(&ratatoskv1.ListInvitesRequest{}))
	if err != nil {
		t.Fatalf("list: %v", err)
	}
	var found bool
	for _, item := range list.Msg.GetInvites() {
		if item.GetCode() != code {
			continue
		}
		found = true
		if item.GetValid() {
			t.Error("a revoked invite is listed as valid")
		}
		if item.GetInvalidReason() != "revoked" {
			t.Errorf("revoked invite reason = %q, want %q", item.GetInvalidReason(), "revoked")
		}
	}
	if !found {
		t.Fatal("the revoked invite vanished from the list; it should be retained")
	}
}
