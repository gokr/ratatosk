package httpserver_test

import (
	"context"
	"testing"

	"connectrpc.com/connect"

	ratatoskv1 "github.com/gokr/ratatosk/server/gen/ratatosk/v1"
	"github.com/gokr/ratatosk/server/gen/ratatosk/v1/ratatoskv1connect"
)

// The in-app deletion path: an authenticated user removes their own account.
//
// It is tested here rather than only in the store because this is what a user can
// actually reach, and because the two properties that matter are at this level:
// the password is required, and afterwards nothing of the account works.
func TestDeleteAccountRequiresThePassword(t *testing.T) {
	h := newHarness(t)
	ctx := context.Background()
	auth := ratatoskv1connect.NewAuthServiceClient(h.srv.Client(), h.baseURL)

	reg, err := auth.Register(ctx, connect.NewRequest(&ratatoskv1.RegisterRequest{
		Username: "ada", Password: "correct horse battery", DisplayName: "Ada",
	}))
	if err != nil {
		t.Fatalf("register: %v", err)
	}
	client := ratatoskv1connect.NewAuthServiceClient(h.srv.Client(), h.baseURL,
		connect.WithInterceptors(bearerInterceptor{token: reg.Msg.GetToken()}))

	// No password: refused, and the account still exists.
	if _, err := client.DeleteAccount(ctx, connect.NewRequest(&ratatoskv1.DeleteAccountRequest{})); codeOf(err) != connect.CodePermissionDenied {
		t.Fatalf("empty password: code = %v, want PermissionDenied", codeOf(err))
	}
	// Wrong password: also refused.
	if _, err := client.DeleteAccount(ctx, connect.NewRequest(&ratatoskv1.DeleteAccountRequest{
		Password: "not it",
	})); codeOf(err) != connect.CodePermissionDenied {
		t.Fatalf("wrong password: code = %v, want PermissionDenied", codeOf(err))
	}
	if _, err := client.GetMe(ctx, connect.NewRequest(&ratatoskv1.GetMeRequest{})); err != nil {
		t.Fatalf("account was affected by a refused deletion: %v", err)
	}

	// The right password deletes it, and the session that did the deleting stops
	// working immediately — there is no "still signed in to a deleted account".
	if _, err := client.DeleteAccount(ctx, connect.NewRequest(&ratatoskv1.DeleteAccountRequest{
		Password: "correct horse battery",
	})); err != nil {
		t.Fatalf("delete: %v", err)
	}
	if _, err := client.GetMe(ctx, connect.NewRequest(&ratatoskv1.GetMeRequest{})); codeOf(err) != connect.CodeUnauthenticated {
		t.Fatalf("after deletion, GetMe code = %v, want Unauthenticated", codeOf(err))
	}
	// And the handle is free again: the account is genuinely gone, not hidden.
	if _, err := auth.Register(ctx, connect.NewRequest(&ratatoskv1.RegisterRequest{
		Username: "ada", Password: "another password entirely",
	})); err != nil {
		t.Fatalf("the username was not released: %v", err)
	}
}

// The deletion must not touch anybody else's data.
func TestDeleteAccountLeavesTheOtherParticipantIntact(t *testing.T) {
	h := newHarness(t)
	ctx := context.Background()
	auth := ratatoskv1connect.NewAuthServiceClient(h.srv.Client(), h.baseURL)

	reg := func(username, display string) (string, string) {
		res, err := auth.Register(ctx, connect.NewRequest(&ratatoskv1.RegisterRequest{
			Username: username, Password: "correct horse battery", DisplayName: display,
		}))
		if err != nil {
			t.Fatalf("register %s: %v", username, err)
		}
		return res.Msg.GetToken(), res.Msg.GetUser().GetId()
	}
	adaToken, _ := reg("ada", "Ada")
	graceToken, graceID := reg("grace", "Grace")

	adaChat := ratatoskv1connect.NewChatServiceClient(h.srv.Client(), h.baseURL,
		connect.WithInterceptors(bearerInterceptor{token: adaToken}))
	graceChat := ratatoskv1connect.NewChatServiceClient(h.srv.Client(), h.baseURL,
		connect.WithInterceptors(bearerInterceptor{token: graceToken}))

	// Ada and Grace talk; Ada also sends a message in a group the two of them are
	// in, so both halves of the deletion rule are exercised.
	direct, err := adaChat.CreateDirectConversation(ctx, connect.NewRequest(&ratatoskv1.CreateDirectConversationRequest{Username: "grace"}))
	if err != nil {
		t.Fatalf("direct: %v", err)
	}
	if _, err := adaChat.SendMessage(ctx, connect.NewRequest(&ratatoskv1.SendMessageRequest{
		ConversationId: direct.Msg.GetConversation().GetId(), Text: "before",
	})); err != nil {
		t.Fatalf("send: %v", err)
	}
	group, err := graceChat.CreateGroupConversation(ctx, connect.NewRequest(&ratatoskv1.CreateGroupConversationRequest{
		Title: "Crew", Usernames: []string{"ada"},
	}))
	if err != nil {
		t.Fatalf("group: %v", err)
	}
	if _, err := adaChat.SendMessage(ctx, connect.NewRequest(&ratatoskv1.SendMessageRequest{
		ConversationId: group.Msg.GetConversation().GetId(), Text: "in the group",
	})); err != nil {
		t.Fatalf("group send: %v", err)
	}

	adaAuth := ratatoskv1connect.NewAuthServiceClient(h.srv.Client(), h.baseURL,
		connect.WithInterceptors(bearerInterceptor{token: adaToken}))
	if _, err := adaAuth.DeleteAccount(ctx, connect.NewRequest(&ratatoskv1.DeleteAccountRequest{
		Password: "correct horse battery",
	})); err != nil {
		t.Fatalf("delete: %v", err)
	}

	// Grace is untouched and can still use her account.
	if _, err := graceChat.ListConversations(ctx, connect.NewRequest(&ratatoskv1.ListConversationsRequest{})); err != nil {
		t.Fatalf("grace's account broke: %v", err)
	}
	_ = graceID

	// The direct conversation went with Ada: an empty thread named after a
	// departed account is worse than no thread.
	if _, err := graceChat.GetConversation(ctx, connect.NewRequest(&ratatoskv1.GetConversationRequest{
		ConversationId: direct.Msg.GetConversation().GetId(),
	})); codeOf(err) != connect.CodeNotFound {
		t.Errorf("the direct conversation survived: code = %v, want NotFound", codeOf(err))
	}

	// The group survived with its history: this store keeps messages gapless, so
	// deleting from the middle would shift every later sequence number.
	msgs, err := graceChat.ListMessages(ctx, connect.NewRequest(&ratatoskv1.ListMessagesRequest{
		ConversationId: group.Msg.GetConversation().GetId(),
	}))
	if err != nil {
		t.Fatalf("group messages: %v", err)
	}
	found := false
	for _, m := range msgs.Msg.GetMessages() {
		if m.GetText() == "in the group" {
			found = true
		}
	}
	if !found {
		t.Error("the group lost the departed member's message, which must stay for the others")
	}
}
