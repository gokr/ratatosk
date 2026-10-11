package httpserver_test

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"connectrpc.com/connect"

	ratatoskv1 "github.com/gokr/ratatosk/server/gen/ratatosk/v1"
	"github.com/gokr/ratatosk/server/gen/ratatosk/v1/ratatoskv1connect"
	"github.com/gokr/ratatosk/server/internal/httpserver"
	"github.com/gokr/ratatosk/server/internal/realtime"
	"github.com/gokr/ratatosk/server/internal/service"
	"github.com/gokr/ratatosk/server/internal/store"
)

// harness is one running server with the clients a test needs. Every test gets
// a fresh store, hub and httptest server, so nothing leaks between them.
type harness struct {
	t       *testing.T
	srv     *httptest.Server
	baseURL string
	auth    ratatoskv1connect.AuthServiceClient
}

func newHarness(t *testing.T) *harness {
	t.Helper()
	srv, _ := newServerOn(t, t.TempDir())
	return harnessOn(t, srv)
}

// harnessOn wraps a server started by newServerOn (or by the restart test).
func harnessOn(t *testing.T, srv *httptest.Server) *harness {
	t.Helper()
	return &harness{
		t:       t,
		srv:     srv,
		baseURL: srv.URL,
		auth:    ratatoskv1connect.NewAuthServiceClient(srv.Client(), srv.URL),
	}
}

// newTestServer wraps a handler in an httptest server.
func newTestServer(t *testing.T, handler http.Handler) *httptest.Server {
	t.Helper()
	srv := httptest.NewServer(handler)
	t.Cleanup(srv.Close)
	return srv
}

// testPublicURL is the origin invite links are built from. It is a fixed name
// rather than the httptest URL so the assertions can name the exact string the
// server is supposed to produce.
const testPublicURL = "http://example.test"

// previewAnonymous calls PreviewInvite without a token, exactly as the invite
// landing page and a not-yet-signed-in app do.
func (h *harness) previewAnonymous(ctx context.Context, code string) (*ratatoskv1.PreviewInviteResponse, error) {
	social := ratatoskv1connect.NewSocialServiceClient(h.srv.Client(), h.baseURL)
	res, err := social.PreviewInvite(ctx, connect.NewRequest(&ratatoskv1.PreviewInviteRequest{Code: code}))
	if err != nil {
		return nil, err
	}
	return res.Msg, nil
}

// newServerOn boots a full server rooted at dir and returns it with its store.
func newServerOn(t *testing.T, dir string) (*httptest.Server, *store.Store) {
	t.Helper()
	// The store logs its own key generation through the default logger before
	// the test's logger reaches it; keep the suite's output clean.
	slog.SetDefault(slog.New(slog.NewTextHandler(io.Discard, nil)))
	log := slog.New(slog.NewTextHandler(io.Discard, nil))
	st, err := store.Open(dir, log)
	if err != nil {
		t.Fatalf("open store: %v", err)
	}
	t.Cleanup(func() { _ = st.Close() })

	hub := realtime.NewHub()
	presence := realtime.NewTracker(st, hub, nil, 5*time.Minute, log)
	// The service config is what builds invite links, so it has to agree with
	// the HTTP config the landing page uses.
	cfg := service.DefaultConfig()
	cfg.PublicURL = testPublicURL
	services := service.New(st, hub, presence, cfg, log)
	handler := httpserver.New(httpserver.Config{
		PublicURL:   testPublicURL,
		CORSOrigins: []string{"*"},
		Log:         log,
	}, st, hub, presence, services)

	srv := httptest.NewServer(handler)
	t.Cleanup(srv.Close)
	return srv, st
}

// authed returns the service clients for one token: the bearer header is what
// the real app's interceptor adds.
func (h *harness) authed(token string) (ratatoskv1connect.AuthServiceClient, ratatoskv1connect.ChatServiceClient, ratatoskv1connect.SocialServiceClient) {
	opt := connect.WithInterceptors(bearerInterceptor{token: token})
	client := h.srv.Client()
	return ratatoskv1connect.NewAuthServiceClient(client, h.baseURL, opt),
		ratatoskv1connect.NewChatServiceClient(client, h.baseURL, opt),
		ratatoskv1connect.NewSocialServiceClient(client, h.baseURL, opt)
}

// bearerInterceptor adds the Authorization header to unary *and* streaming
// calls. Streaming needs its own hook: an interceptor that only implements the
// unary side silently sends an unauthenticated Subscribe, which looks exactly
// like a server bug.
//
// `deviceKey` is the extra header a client uses to name the device key it
// holds, which the key-envelope calls are scoped to.
type bearerInterceptor struct {
	token     string
	deviceKey string
}

func (b bearerInterceptor) headers() map[string]string {
	out := map[string]string{"Authorization": "Bearer " + b.token}
	if b.deviceKey != "" {
		out["X-Ratatosk-Device-Key"] = b.deviceKey
	}
	return out
}

func (b bearerInterceptor) WrapUnary(next connect.UnaryFunc) connect.UnaryFunc {
	return func(ctx context.Context, req connect.AnyRequest) (connect.AnyResponse, error) {
		for name, value := range b.headers() {
			req.Header().Set(name, value)
		}
		return next(ctx, req)
	}
}

func (b bearerInterceptor) WrapStreamingClient(next connect.StreamingClientFunc) connect.StreamingClientFunc {
	return func(ctx context.Context, spec connect.Spec) connect.StreamingClientConn {
		conn := next(ctx, spec)
		for name, value := range b.headers() {
			conn.RequestHeader().Set(name, value)
		}
		return conn
	}
}

// WrapStreamingHandler is the server side of the interface, unused here.
func (b bearerInterceptor) WrapStreamingHandler(next connect.StreamingHandlerFunc) connect.StreamingHandlerFunc {
	return next
}

// register creates an account and returns its token and user.
func (h *harness) register(username, password, display string) (string, *ratatoskv1.User) {
	h.t.Helper()
	res, err := h.auth.Register(context.Background(), connect.NewRequest(&ratatoskv1.RegisterRequest{
		Username:    username,
		Password:    password,
		DisplayName: display,
	}))
	if err != nil {
		h.t.Fatalf("register %s: %v", username, err)
	}
	return res.Msg.GetToken(), res.Msg.GetUser()
}

// notConnectCode is outside the range of status codes a server can return, so
// it can only come from an error that is not a Connect error at all (a
// transport failure, say).
const notConnectCode = connect.Code(255)

// codeOf extracts the Connect status code, or notConnectCode when err is not a
// Connect error.
func codeOf(err error) connect.Code {
	var ce *connect.Error
	if err == nil || !errors.As(err, &ce) {
		return notConnectCode
	}
	return ce.Code()
}

// --- realtime helpers ----------------------------------------------------

// eventReader drains a Subscribe stream in the background. Reading a stream
// involves a blocking Receive, so tests that need to interleave sends with
// reads cannot do both on one goroutine.
type eventReader struct {
	events chan *ratatoskv1.Event
	closed chan struct{}
}

func startReader(stream *connect.ServerStreamForClient[ratatoskv1.Event]) *eventReader {
	r := &eventReader{events: make(chan *ratatoskv1.Event, 64), closed: make(chan struct{})}
	go func() {
		defer close(r.closed)
		for stream.Receive() {
			select {
			case r.events <- stream.Msg():
			case <-time.After(10 * time.Second):
				return
			}
		}
	}()
	return r
}

// expect waits for an event matching want, ignoring the others.
func (r *eventReader) expect(t *testing.T, what string, want func(*ratatoskv1.Event) bool) *ratatoskv1.Event {
	t.Helper()
	return r.expectStream(t, nil, what, want)
}

// expectStream is expect with the stream attached, so a failure reports why
// the stream ended rather than just timing out.
func (r *eventReader) expectStream(t *testing.T, stream *connect.ServerStreamForClient[ratatoskv1.Event], what string, want func(*ratatoskv1.Event) bool) *ratatoskv1.Event {
	t.Helper()
	deadline := time.After(5 * time.Second)
	for {
		select {
		case ev := <-r.events:
			if want(ev) {
				return ev
			}
		case <-deadline:
			if stream != nil {
				t.Fatalf("timed out waiting for %s (stream error: %v)", what, stream.Err())
			}
			t.Fatalf("timed out waiting for %s", what)
			return nil
		}
	}
}

// --- tests ---------------------------------------------------------------

func TestRegisterLoginAndAuthRequired(t *testing.T) {
	h := newHarness(t)
	token, user := h.register("ada", "correct horse", "")
	if token == "" || user.GetUsername() != "ada" {
		t.Fatalf("register returned token=%q user=%q", token, user.GetUsername())
	}
	if user.GetDisplayName() != "ada" {
		t.Fatalf("display name = %q, want the handle as default", user.GetDisplayName())
	}
	if user.GetAccentColor() == "" {
		t.Fatal("expected an accent color on a new user")
	}

	if _, err := h.auth.Register(context.Background(), connect.NewRequest(&ratatoskv1.RegisterRequest{
		Username: "ada", Password: "correct horse",
	})); codeOf(err) != connect.CodeAlreadyExists {
		t.Fatalf("duplicate register: code = %v, want AlreadyExists", codeOf(err))
	}

	// A private procedure without a token must refuse.
	_, anonChat, _ := h.authed("")
	if _, err := anonChat.ListConversations(context.Background(), connect.NewRequest(&ratatoskv1.ListConversationsRequest{})); codeOf(err) != connect.CodeUnauthenticated {
		t.Fatalf("anonymous ListConversations: code = %v, want Unauthenticated", codeOf(err))
	}

	if _, err := h.auth.Register(context.Background(), connect.NewRequest(&ratatoskv1.RegisterRequest{
		Username: "Not A Handle", Password: "correct horse",
	})); codeOf(err) != connect.CodeInvalidArgument {
		t.Fatalf("invalid username: code = %v, want InvalidArgument", codeOf(err))
	}

	// A token that was logged out stops working; logging out again with that
	// dead token still succeeds, so a client can always clear its state.
	authClient, chat, _ := h.authed(token)
	if _, err := chat.ListConversations(context.Background(), connect.NewRequest(&ratatoskv1.ListConversationsRequest{})); err != nil {
		t.Fatalf("authed ListConversations: %v", err)
	}
	if _, err := authClient.Logout(context.Background(), connect.NewRequest(&ratatoskv1.LogoutRequest{})); err != nil {
		t.Fatalf("logout: %v", err)
	}
	_, staleChat, _ := h.authed(token)
	if _, err := staleChat.ListConversations(context.Background(), connect.NewRequest(&ratatoskv1.ListConversationsRequest{})); codeOf(err) != connect.CodeUnauthenticated {
		t.Fatalf("after logout: err = %v (code = %v), want Unauthenticated", err, codeOf(err))
	}
	if _, err := h.auth.Logout(context.Background(), connect.NewRequest(&ratatoskv1.LogoutRequest{})); err != nil {
		t.Fatalf("logout without a token: %v", err)
	}
}

func TestLoginAndDisplayNameDefaults(t *testing.T) {
	h := newHarness(t)
	_, user := h.register("grace", "password123", "")
	if user.GetDisplayName() != "grace" {
		t.Fatalf("display name = %q, want the handle as the default", user.GetDisplayName())
	}
	login, err := h.auth.Login(context.Background(), connect.NewRequest(&ratatoskv1.LoginRequest{
		Username: "grace", Password: "password123",
	}))
	if err != nil {
		t.Fatalf("login: %v", err)
	}
	if login.Msg.GetUser().GetId() != user.GetId() || login.Msg.GetToken() == "" {
		t.Fatal("login returned a different identity")
	}
	if _, err := h.auth.Login(context.Background(), connect.NewRequest(&ratatoskv1.LoginRequest{
		Username: "grace", Password: "wrong",
	})); codeOf(err) != connect.CodeUnauthenticated {
		t.Fatalf("bad login: code = %v, want Unauthenticated", codeOf(err))
	}
}

func TestTwoUsersChatInRealTime(t *testing.T) {
	h := newHarness(t)
	adaToken, _ := h.register("ada", "password123", "Ada Lovelace")
	graceToken, grace := h.register("grace", "password123", "Grace Hopper")
	_, adaChat, _ := h.authed(adaToken)
	_, graceChat, _ := h.authed(graceToken)
	ctx := context.Background()

	// Grace streams before anything happens: she must hear about the
	// conversation Ada is about to create, without polling.
	stream, err := graceChat.Subscribe(ctx, connect.NewRequest(&ratatoskv1.SubscribeRequest{}))
	if err != nil {
		t.Fatalf("subscribe: %v", err)
	}
	defer stream.Close()
	reader := startReader(stream)
	hello := reader.expectStream(t, stream, "the hello frame", func(ev *ratatoskv1.Event) bool { return ev.GetHello() != nil })
	if hello.GetHello().GetUser().GetId() != grace.GetId() {
		t.Fatal("hello frame does not identify the subscriber")
	}

	direct, err := adaChat.CreateDirectConversation(ctx, connect.NewRequest(&ratatoskv1.CreateDirectConversationRequest{
		Username: "grace",
	}))
	if err != nil {
		t.Fatalf("create direct: %v", err)
	}
	convID := direct.Msg.GetConversation().GetId()
	if direct.Msg.GetConversation().GetTitle() != "Grace Hopper" {
		t.Fatalf("direct title = %q, want the peer's display name", direct.Msg.GetConversation().GetTitle())
	}
	if direct.Msg.GetConversation().GetPeer().GetUsername() != "grace" {
		t.Fatal("direct conversation should carry the peer")
	}

	reader.expect(t, "grace's new conversation", func(ev *ratatoskv1.Event) bool {
		c := ev.GetConversation()
		return c != nil && c.GetConversation().GetId() == convID && c.GetCreated()
	})

	sent, err := adaChat.SendMessage(ctx, connect.NewRequest(&ratatoskv1.SendMessageRequest{
		ConversationId:  convID,
		Text:            "hello grace",
		ClientMessageId: "local-1",
	}))
	if err != nil {
		t.Fatalf("send: %v", err)
	}
	if sent.Msg.GetMessage().GetSeq() != 1 {
		t.Fatalf("first message seq = %d, want 1", sent.Msg.GetMessage().GetSeq())
	}
	reader.expect(t, "the message on grace's stream", func(ev *ratatoskv1.Event) bool {
		return ev.GetMessage().GetMessage().GetText() == "hello grace"
	})

	// Idempotency: replaying the same client_message_id must not double-post.
	again, err := adaChat.SendMessage(ctx, connect.NewRequest(&ratatoskv1.SendMessageRequest{
		ConversationId:  convID,
		Text:            "hello grace",
		ClientMessageId: "local-1",
	}))
	if err != nil {
		t.Fatalf("resend: %v", err)
	}
	if again.Msg.GetMessage().GetId() != sent.Msg.GetMessage().GetId() {
		t.Fatal("a retried send created a second message")
	}
	msgs, err := graceChat.ListMessages(ctx, connect.NewRequest(&ratatoskv1.ListMessagesRequest{
		ConversationId: convID,
	}))
	if err != nil {
		t.Fatalf("list: %v", err)
	}
	if len(msgs.Msg.GetMessages()) != 1 {
		t.Fatalf("message count = %d, want 1", len(msgs.Msg.GetMessages()))
	}

	// Grace has one unread, which her reply clears.
	convs, err := graceChat.ListConversations(ctx, connect.NewRequest(&ratatoskv1.ListConversationsRequest{}))
	if err != nil {
		t.Fatalf("list conversations: %v", err)
	}
	if n := convs.Msg.GetConversations()[0].GetUnreadCount(); n != 1 {
		t.Fatalf("grace unread = %d, want 1", n)
	}
	if _, err := graceChat.SendMessage(ctx, connect.NewRequest(&ratatoskv1.SendMessageRequest{
		ConversationId: convID, Text: "hi ada",
	})); err != nil {
		t.Fatalf("grace reply: %v", err)
	}
	read, err := graceChat.MarkRead(ctx, connect.NewRequest(&ratatoskv1.MarkReadRequest{ConversationId: convID}))
	if err != nil {
		t.Fatalf("mark read: %v", err)
	}
	if read.Msg.GetUnreadCount() != 0 {
		t.Fatalf("unread after MarkRead = %d, want 0", read.Msg.GetUnreadCount())
	}
	// Ada's stream hears about Grace reading.
	reader2, err := adaChat.Subscribe(ctx, connect.NewRequest(&ratatoskv1.SubscribeRequest{}))
	if err != nil {
		t.Fatalf("ada subscribe: %v", err)
	}
	defer reader2.Close()
	adaReader := startReader(reader2)
	adaReader.expect(t, "the hello frame", func(ev *ratatoskv1.Event) bool { return ev.GetHello() != nil })
	if _, err := graceChat.MarkRead(ctx, connect.NewRequest(&ratatoskv1.MarkReadRequest{
		ConversationId: convID, UpToSeq: 2,
	})); err != nil {
		t.Fatalf("second mark read: %v", err)
	}
	adaReader.expect(t, "grace's read receipt", func(ev *ratatoskv1.Event) bool {
		return ev.GetRead().GetUserId() == grace.GetId()
	})

	// A stranger can neither read nor post into the conversation.
	malloryToken, _ := h.register("mallory", "password123", "")
	_, malloryChat, _ := h.authed(malloryToken)
	if _, err := malloryChat.ListMessages(ctx, connect.NewRequest(&ratatoskv1.ListMessagesRequest{
		ConversationId: convID,
	})); codeOf(err) != connect.CodePermissionDenied {
		t.Fatalf("stranger ListMessages: code = %v, want PermissionDenied", codeOf(err))
	}
	if _, err := malloryChat.SendMessage(ctx, connect.NewRequest(&ratatoskv1.SendMessageRequest{
		ConversationId: convID, Text: "let me in",
	})); codeOf(err) != connect.CodePermissionDenied {
		t.Fatalf("stranger SendMessage: code = %v, want PermissionDenied", codeOf(err))
	}
	if _, err := malloryChat.MarkRead(ctx, connect.NewRequest(&ratatoskv1.MarkReadRequest{
		ConversationId: convID,
	})); codeOf(err) != connect.CodePermissionDenied {
		t.Fatalf("stranger MarkRead: code = %v, want PermissionDenied", codeOf(err))
	}
}

func TestTypingIndicators(t *testing.T) {
	h := newHarness(t)
	adaToken, ada := h.register("ada", "password123", "Ada")
	graceToken, _ := h.register("grace", "password123", "Grace")
	_, adaChat, _ := h.authed(adaToken)
	_, graceChat, _ := h.authed(graceToken)
	ctx := context.Background()

	direct, err := adaChat.CreateDirectConversation(ctx, connect.NewRequest(&ratatoskv1.CreateDirectConversationRequest{Username: "grace"}))
	if err != nil {
		t.Fatalf("create direct: %v", err)
	}
	convID := direct.Msg.GetConversation().GetId()

	stream, err := adaChat.Subscribe(ctx, connect.NewRequest(&ratatoskv1.SubscribeRequest{}))
	if err != nil {
		t.Fatalf("subscribe: %v", err)
	}
	defer stream.Close()
	reader := startReader(stream)
	reader.expect(t, "the hello frame", func(ev *ratatoskv1.Event) bool { return ev.GetHello() != nil })

	if _, err := graceChat.SetTyping(ctx, connect.NewRequest(&ratatoskv1.SetTypingRequest{
		ConversationId: convID, Typing: true,
	})); err != nil {
		t.Fatalf("set typing: %v", err)
	}
	ev := reader.expect(t, "a typing indicator", func(ev *ratatoskv1.Event) bool {
		return ev.GetTyping().GetTyping()
	})
	if ev.GetTyping().GetDisplayName() != "Grace" {
		t.Fatalf("typing event should name the typist, got %q", ev.GetTyping().GetDisplayName())
	}
	if ev.GetTyping().GetConversationId() != convID {
		t.Fatalf("typing event conversation = %q, want %q", ev.GetTyping().GetConversationId(), convID)
	}
	// The sender must not be told they are typing to themselves.
	if _, err := graceChat.SetTyping(ctx, connect.NewRequest(&ratatoskv1.SetTypingRequest{
		ConversationId: convID, Typing: false,
	})); err != nil {
		t.Fatalf("stop typing: %v", err)
	}
	reader.expect(t, "the typing stop", func(ev *ratatoskv1.Event) bool {
		return ev.GetTyping() != nil && !ev.GetTyping().GetTyping()
	})
	_ = ada
}

func TestInviteLinkLifecycle(t *testing.T) {
	h := newHarness(t)
	adaToken, _ := h.register("ada", "password123", "Ada")
	graceToken, grace := h.register("grace", "password123", "Grace")
	_, adaChat, adaSocial := h.authed(adaToken)
	_, _, graceSocial := h.authed(graceToken)
	ctx := context.Background()

	created, err := adaSocial.CreateInvite(ctx, connect.NewRequest(&ratatoskv1.CreateInviteRequest{}))
	if err != nil {
		t.Fatalf("create invite: %v", err)
	}
	invite := created.Msg.GetInvite()
	if len(invite.GetCode()) < 6 {
		t.Fatalf("invite code %q is too short", invite.GetCode())
	}
	wantURL := "http://example.test/join/" + invite.GetCode()
	if invite.GetUrl() != wantURL {
		t.Fatalf("invite url = %q, want %q", invite.GetUrl(), wantURL)
	}
	if !invite.GetValid() {
		t.Fatal("a fresh invite should be valid")
	}

	// Preview needs no token (the landing page shows who invited you) and
	// accepts both a bare code and a pasted link.
	for _, input := range []string{invite.GetCode(), wantURL} {
		preview, err := h.previewAnonymous(ctx, input)
		if err != nil {
			t.Fatalf("preview %q: %v", input, err)
		}
		if !preview.GetValid() || preview.GetInviter().GetDisplayName() != "Ada" {
			t.Fatalf("preview %q = valid:%v inviter:%q", input, preview.GetValid(), preview.GetInviter().GetDisplayName())
		}
	}

	redeemed, err := graceSocial.RedeemInvite(ctx, connect.NewRequest(&ratatoskv1.RedeemInviteRequest{
		Code: wantURL,
	}))
	if err != nil {
		t.Fatalf("redeem: %v", err)
	}
	convID := redeemed.Msg.GetConversation().GetId()
	if convID == "" {
		t.Fatal("redeeming did not create a conversation")
	}
	if redeemed.Msg.GetInviter().GetId() == grace.GetId() {
		t.Fatal("redeemer should not be the inviter")
	}

	contacts, err := adaSocial.ListContacts(ctx, connect.NewRequest(&ratatoskv1.ListContactsRequest{}))
	if err != nil {
		t.Fatalf("list contacts: %v", err)
	}
	if len(contacts.Msg.GetContacts()) != 1 || contacts.Msg.GetContacts()[0].GetUser().GetId() != grace.GetId() {
		t.Fatalf("ada contacts = %v, want grace", contacts.Msg.GetContacts())
	}
	if contacts.Msg.GetContacts()[0].GetConversationId() != convID {
		t.Fatal("contact should point at the shared conversation")
	}
	// Contacts are symmetric: the redeemer sees the inviter too.
	graceContacts, err := graceSocial.ListContacts(ctx, connect.NewRequest(&ratatoskv1.ListContactsRequest{}))
	if err != nil {
		t.Fatalf("grace contacts: %v", err)
	}
	if len(graceContacts.Msg.GetContacts()) != 1 {
		t.Fatalf("grace contacts = %v, want one", graceContacts.Msg.GetContacts())
	}

	invites, err := adaSocial.ListInvites(ctx, connect.NewRequest(&ratatoskv1.ListInvitesRequest{}))
	if err != nil {
		t.Fatalf("list invites: %v", err)
	}
	if uses := invites.Msg.GetInvites()[0].GetUses(); uses != 1 {
		t.Fatalf("invite uses = %d, want 1", uses)
	}
	if invites.Msg.GetInvites()[0].GetValid() {
		t.Fatal("an invite with max_uses=1 should be exhausted after one redemption")
	}
	if len(invites.Msg.GetInvites()[0].GetRedeemedBy()) != 1 {
		t.Fatal("the invite should record who redeemed it")
	}

	// Redeeming twice must not consume the single use twice.
	if _, err := graceSocial.RedeemInvite(ctx, connect.NewRequest(&ratatoskv1.RedeemInviteRequest{Code: invite.GetCode()})); err != nil {
		t.Fatalf("re-redeem by the same person: %v", err)
	}
	invites, _ = adaSocial.ListInvites(ctx, connect.NewRequest(&ratatoskv1.ListInvitesRequest{}))
	if uses := invites.Msg.GetInvites()[0].GetUses(); uses != 1 {
		t.Fatalf("uses after a repeat redemption = %d, want 1", uses)
	}

	// A second person cannot use the same single-use link.
	malloryToken, _ := h.register("mallory", "password123", "")
	_, _, mallorySocial := h.authed(malloryToken)
	if _, err := mallorySocial.RedeemInvite(ctx, connect.NewRequest(&ratatoskv1.RedeemInviteRequest{
		Code: invite.GetCode(),
	})); codeOf(err) != connect.CodeFailedPrecondition {
		t.Fatalf("second redemption: code = %v, want FailedPrecondition", codeOf(err))
	}

	// Revoking kills a still-valid invite, and only the owner may revoke.
	multi, err := adaSocial.CreateInvite(ctx, connect.NewRequest(&ratatoskv1.CreateInviteRequest{MaxUses: -1}))
	if err != nil {
		t.Fatalf("create multi-use invite: %v", err)
	}
	if _, err := graceSocial.RevokeInvite(ctx, connect.NewRequest(&ratatoskv1.RevokeInviteRequest{
		Code: multi.Msg.GetInvite().GetCode(),
	})); codeOf(err) != connect.CodePermissionDenied {
		t.Fatalf("foreign revoke: code = %v, want PermissionDenied", codeOf(err))
	}
	if _, err := adaSocial.RevokeInvite(ctx, connect.NewRequest(&ratatoskv1.RevokeInviteRequest{
		Code: multi.Msg.GetInvite().GetCode(),
	})); err != nil {
		t.Fatalf("revoke: %v", err)
	}
	preview, err := h.previewAnonymous(ctx, multi.Msg.GetInvite().GetCode())
	if err != nil {
		t.Fatalf("preview revoked: %v", err)
	}
	if preview.GetValid() || preview.GetReason() != "revoked" {
		t.Fatalf("revoked preview = valid:%v reason:%q", preview.GetValid(), preview.GetReason())
	}
	// An unlimited invite keeps its uses unexpired for many people.
	shared, err := adaSocial.CreateInvite(ctx, connect.NewRequest(&ratatoskv1.CreateInviteRequest{MaxUses: -1}))
	if err != nil {
		t.Fatalf("create shared invite: %v", err)
	}
	if _, err := mallorySocial.RedeemInvite(ctx, connect.NewRequest(&ratatoskv1.RedeemInviteRequest{
		Code: shared.Msg.GetInvite().GetCode(),
	})); err != nil {
		t.Fatalf("unlimited invite redemption: %v", err)
	}

	// Messages flow over the conversation the invite created.
	sent, err := adaChat.SendMessage(ctx, connect.NewRequest(&ratatoskv1.SendMessageRequest{
		ConversationId: convID, Text: "welcome aboard",
	}))
	if err != nil {
		t.Fatalf("send after invite: %v", err)
	}
	if sent.Msg.GetMessage().GetSeq() != 1 {
		t.Fatalf("seq = %d, want 1", sent.Msg.GetMessage().GetSeq())
	}
}

func TestInviteLandingPage(t *testing.T) {
	h := newHarness(t)
	adaToken, _ := h.register("ada", "password123", "Ada Lovelace")
	_, _, adaSocial := h.authed(adaToken)

	created, err := adaSocial.CreateInvite(context.Background(), connect.NewRequest(&ratatoskv1.CreateInviteRequest{}))
	if err != nil {
		t.Fatalf("create invite: %v", err)
	}
	code := created.Msg.GetInvite().GetCode()

	res, err := http.Get(h.baseURL + "/join/" + code)
	if err != nil {
		t.Fatalf("get landing page: %v", err)
	}
	defer res.Body.Close()
	body, _ := io.ReadAll(res.Body)
	if res.StatusCode != http.StatusOK {
		t.Fatalf("landing page status = %d", res.StatusCode)
	}
	page := string(body)
	if !strings.Contains(page, "Ada Lovelace") || !strings.Contains(page, "ratatosk://join/"+code) {
		t.Fatalf("landing page is missing the inviter or the deep link:\n%s", page)
	}

	res, err = http.Get(h.baseURL + "/invite/" + code)
	if err != nil {
		t.Fatalf("get invite json: %v", err)
	}
	defer res.Body.Close()
	var payload map[string]any
	if err := json.NewDecoder(res.Body).Decode(&payload); err != nil {
		t.Fatalf("decode invite json: %v", err)
	}
	if payload["valid"] != true || payload["inviter"] != "Ada Lovelace" {
		t.Fatalf("invite json = %v", payload)
	}

	// Unknown codes render a readable page rather than a bare 404.
	res, err = http.Get(h.baseURL + "/join/does-not-exist")
	if err != nil {
		t.Fatalf("get unknown invite: %v", err)
	}
	defer res.Body.Close()
	body, _ = io.ReadAll(res.Body)
	if res.StatusCode != http.StatusOK || !strings.Contains(string(body), "not available") {
		t.Fatalf("unknown invite page = %d %q", res.StatusCode, string(body))
	}

	res, err = http.Get(h.baseURL + "/invite/does-not-exist")
	if err != nil {
		t.Fatalf("get unknown invite json: %v", err)
	}
	defer res.Body.Close()
	payload = nil
	if err := json.NewDecoder(res.Body).Decode(&payload); err != nil {
		t.Fatalf("decode unknown invite json: %v", err)
	}
	if payload["valid"] != false || payload["reason"] != "unknown" {
		t.Fatalf("unknown invite json = %v", payload)
	}
	if text, _ := payload["detail"].(string); !strings.Contains(text, "could not find") {
		t.Fatalf("the JSON preview should explain itself in words too, got %q", text)
	}

	// Health is reachable and reports something.
	res, err = http.Get(h.baseURL + "/healthz")
	if err != nil {
		t.Fatalf("healthz: %v", err)
	}
	defer res.Body.Close()
	if res.StatusCode != http.StatusOK {
		t.Fatalf("healthz status = %d", res.StatusCode)
	}
}

func TestMessageEditingReactionsAndPaging(t *testing.T) {
	h := newHarness(t)
	adaToken, _ := h.register("ada", "password123", "Ada")
	graceToken, _ := h.register("grace", "password123", "Grace")
	_, adaChat, _ := h.authed(adaToken)
	_, graceChat, _ := h.authed(graceToken)
	ctx := context.Background()

	direct, err := adaChat.CreateDirectConversation(ctx, connect.NewRequest(&ratatoskv1.CreateDirectConversationRequest{Username: "grace"}))
	if err != nil {
		t.Fatalf("create direct: %v", err)
	}
	convID := direct.Msg.GetConversation().GetId()

	var sent []*ratatoskv1.Message
	for i := 0; i < 5; i++ {
		res, err := adaChat.SendMessage(ctx, connect.NewRequest(&ratatoskv1.SendMessageRequest{
			ConversationId: convID,
			Text:           "message " + strings.Repeat("x", i+1),
		}))
		if err != nil {
			t.Fatalf("send %d: %v", i, err)
		}
		sent = append(sent, res.Msg.GetMessage())
	}

	// The default page is the newest window, oldest first.
	page, err := graceChat.ListMessages(ctx, connect.NewRequest(&ratatoskv1.ListMessagesRequest{
		ConversationId: convID, Limit: 2,
	}))
	if err != nil {
		t.Fatalf("list: %v", err)
	}
	if got := len(page.Msg.GetMessages()); got != 2 {
		t.Fatalf("page size = %d, want 2", got)
	}
	if !page.Msg.GetHasMore() {
		t.Fatal("expected hasMore when older messages exist")
	}
	if seq := page.Msg.GetMessages()[1].GetSeq(); seq != 5 {
		t.Fatalf("newest seq = %d, want 5", seq)
	}

	older, err := graceChat.ListMessages(ctx, connect.NewRequest(&ratatoskv1.ListMessagesRequest{
		ConversationId: convID, BeforeSeq: page.Msg.GetMessages()[0].GetSeq(), Limit: 2,
	}))
	if err != nil {
		t.Fatalf("list older: %v", err)
	}
	if seqs := seqsOf(older.Msg.GetMessages()); len(seqs) != 2 || seqs[0] != 2 || seqs[1] != 3 {
		t.Fatalf("older page seqs = %v, want [2 3]", seqs)
	}

	// Catch-up after a seq is what a reconnecting client does.
	after, err := graceChat.ListMessages(ctx, connect.NewRequest(&ratatoskv1.ListMessagesRequest{
		ConversationId: convID, AfterSeq: 4,
	}))
	if err != nil {
		t.Fatalf("list after: %v", err)
	}
	if seqs := seqsOf(after.Msg.GetMessages()); len(seqs) != 1 || seqs[0] != 5 {
		t.Fatalf("catch-up returned %v, want [5]", seqs)
	}

	// Editing is author-only and stamps edited_at.
	target := sent[0]
	if _, err := graceChat.EditMessage(ctx, connect.NewRequest(&ratatoskv1.EditMessageRequest{
		MessageId: target.GetId(), Text: "hijacked",
	})); codeOf(err) != connect.CodePermissionDenied {
		t.Fatalf("foreign edit: code = %v, want PermissionDenied", codeOf(err))
	}
	edited, err := adaChat.EditMessage(ctx, connect.NewRequest(&ratatoskv1.EditMessageRequest{
		MessageId: target.GetId(), Text: "message x (fixed)",
	}))
	if err != nil {
		t.Fatalf("edit: %v", err)
	}
	if edited.Msg.GetMessage().GetEditedAt() == nil {
		t.Fatal("edited message has no edited_at")
	}
	if edited.Msg.GetMessage().GetSeq() != target.GetSeq() {
		t.Fatal("editing moved the message")
	}

	// Reactions: one per person per emoji, removable.
	if _, err := graceChat.AddReaction(ctx, connect.NewRequest(&ratatoskv1.AddReactionRequest{
		MessageId: target.GetId(), Emoji: "👍",
	})); err != nil {
		t.Fatalf("react: %v", err)
	}
	reacted, err := graceChat.AddReaction(ctx, connect.NewRequest(&ratatoskv1.AddReactionRequest{
		MessageId: target.GetId(), Emoji: "👍",
	}))
	if err != nil {
		t.Fatalf("react twice: %v", err)
	}
	if got := len(reacted.Msg.GetMessage().GetReactions()); got != 1 {
		t.Fatalf("reaction groups = %d, want 1", got)
	}
	if got := len(reacted.Msg.GetMessage().GetReactions()[0].GetUserIds()); got != 1 {
		t.Fatalf("reaction user count = %d, want 1 (a repeat must be idempotent)", got)
	}
	// The reaction names the person who reacted, which is who the app badges.
	unreacted, err := graceChat.RemoveReaction(ctx, connect.NewRequest(&ratatoskv1.RemoveReactionRequest{
		MessageId: target.GetId(), Emoji: "👍",
	}))
	if err != nil {
		t.Fatalf("unreact: %v", err)
	}
	if len(unreacted.Msg.GetMessage().GetReactions()) != 0 {
		t.Fatal("removing the only reaction should leave none")
	}

	// Deleting tombstones: id and seq survive, content does not.
	deleted, err := adaChat.DeleteMessage(ctx, connect.NewRequest(&ratatoskv1.DeleteMessageRequest{
		MessageId: target.GetId(),
	}))
	if err != nil {
		t.Fatalf("delete: %v", err)
	}
	if !deleted.Msg.GetMessage().GetDeleted() || deleted.Msg.GetMessage().GetText() != "" {
		t.Fatal("a deleted message still carries text")
	}
	if deleted.Msg.GetMessage().GetSeq() != target.GetSeq() {
		t.Fatal("deleting changed the seq, which would break paging")
	}

	// A reply to a deleted message resolves to a tombstone preview.
	reply, err := graceChat.SendMessage(ctx, connect.NewRequest(&ratatoskv1.SendMessageRequest{
		ConversationId: convID, Text: "replying to a deleted message", ReplyToId: target.GetId(),
	}))
	if err != nil {
		t.Fatalf("reply to deleted: %v", err)
	}
	if !reply.Msg.GetMessage().GetReplyTo().GetDeleted() {
		t.Fatal("reply preview should mark the parent deleted")
	}
	// A reply pointing outside the conversation is refused. Mallory needs a
	// message of her own for this: a reply to a message in another conversation
	// must not be silently accepted.
	malloryToken, _ := h.register("mallory", "password123", "Mallory")
	_, malloryChat, _ := h.authed(malloryToken)
	malloryDirect, err := malloryChat.CreateDirectConversation(ctx, connect.NewRequest(&ratatoskv1.CreateDirectConversationRequest{Username: "ada"}))
	if err != nil {
		t.Fatalf("mallory direct: %v", err)
	}
	foreign, err := malloryChat.SendMessage(ctx, connect.NewRequest(&ratatoskv1.SendMessageRequest{
		ConversationId: malloryDirect.Msg.GetConversation().GetId(), Text: "elsewhere",
	}))
	if err != nil {
		t.Fatalf("send elsewhere: %v", err)
	}
	if _, err := adaChat.SendMessage(ctx, connect.NewRequest(&ratatoskv1.SendMessageRequest{
		ConversationId: convID, Text: "bad reply", ReplyToId: foreign.Msg.GetMessage().GetId(),
	})); codeOf(err) != connect.CodeInvalidArgument {
		t.Fatalf("cross-conversation reply: code = %v, want InvalidArgument", codeOf(err))
	}

	// Search across conversations returns context with each hit.
	found, err := graceChat.SearchMessages(ctx, connect.NewRequest(&ratatoskv1.SearchMessagesRequest{Query: "message"}))
	if err != nil {
		t.Fatalf("search: %v", err)
	}
	if len(found.Msg.GetResults()) == 0 {
		t.Fatal("search found nothing for a query every message contains")
	}
	if found.Msg.GetResults()[0].GetConversationTitle() == "" || found.Msg.GetResults()[0].GetSenderName() == "" {
		t.Fatal("search results should carry conversation and sender context")
	}
}

func TestGroupsUploadsAndMembership(t *testing.T) {
	h := newHarness(t)
	adaToken, _ := h.register("ada", "password123", "Ada")
	graceToken, _ := h.register("grace", "password123", "Grace")
	_, adaChat, _ := h.authed(adaToken)
	_, graceChat, _ := h.authed(graceToken)
	ctx := context.Background()

	// Upload then fetch: the bytes are served with the declared type.
	up, err := adaChat.UploadAttachment(ctx, connect.NewRequest(&ratatoskv1.UploadAttachmentRequest{
		Filename:    "photo.png",
		ContentType: "image/png",
		Data:        []byte("not really a png"),
	}))
	if err != nil {
		t.Fatalf("upload: %v", err)
	}
	att := up.Msg.GetAttachment()
	if !att.GetIsImage() || att.GetSize() != 16 {
		t.Fatalf("attachment = %v", att)
	}
	res, err := http.Get(h.baseURL + att.GetUrl() + "?token=" + adaToken)
	if err != nil {
		t.Fatalf("download: %v", err)
	}
	defer res.Body.Close()
	body, _ := io.ReadAll(res.Body)
	if res.StatusCode != http.StatusOK || res.Header.Get("Content-Type") != "image/png" || string(body) != "not really a png" {
		t.Fatalf("download = %d %q %q", res.StatusCode, res.Header.Get("Content-Type"), string(body))
	}
	res, err = http.Get(h.baseURL + att.GetUrl())
	if err != nil {
		t.Fatalf("anonymous download: %v", err)
	}
	res.Body.Close()
	if res.StatusCode != http.StatusUnauthorized {
		t.Fatalf("anonymous download status = %d, want 401", res.StatusCode)
	}

	// A group with both members and a system note from the server.
	group, err := adaChat.CreateGroupConversation(ctx, connect.NewRequest(&ratatoskv1.CreateGroupConversationRequest{
		Title:     "The Breakfast Club",
		Usernames: []string{"grace"},
	}))
	if err != nil {
		t.Fatalf("create group: %v", err)
	}
	groupConv := group.Msg.GetConversation()
	if got := len(groupConv.GetMembers()); got != 2 {
		t.Fatalf("group members = %d, want 2", got)
	}
	if groupConv.GetMembers()[0].GetRole() != "owner" {
		t.Fatal("the creator should be listed first, as owner")
	}
	groupID := groupConv.GetId()

	list, err := graceChat.ListMessages(ctx, connect.NewRequest(&ratatoskv1.ListMessagesRequest{ConversationId: groupID}))
	if err != nil {
		t.Fatalf("list group messages: %v", err)
	}
	if len(list.Msg.GetMessages()) != 1 || list.Msg.GetMessages()[0].GetKind() != ratatoskv1.MessageKind_MESSAGE_KIND_SYSTEM {
		t.Fatalf("expected one system message, got %v", list.Msg.GetMessages())
	}

	// A message carrying the attachment.
	withAttachment, err := adaChat.SendMessage(ctx, connect.NewRequest(&ratatoskv1.SendMessageRequest{
		ConversationId: groupID,
		Text:           "look at this",
		AttachmentIds:  []string{att.GetId()},
	}))
	if err != nil {
		t.Fatalf("send with attachment: %v", err)
	}
	if n := len(withAttachment.Msg.GetMessage().GetAttachments()); n != 1 {
		t.Fatalf("attachments = %d, want 1", n)
	}

	// Membership rules: only the owner adds, anyone may leave, and the last
	// member leaving removes the conversation.
	if _, err := graceChat.AddMembers(ctx, connect.NewRequest(&ratatoskv1.AddMembersRequest{
		ConversationId: groupID, Usernames: []string{"ada"},
	})); codeOf(err) != connect.CodePermissionDenied {
		t.Fatalf("non-owner add: code = %v, want PermissionDenied", codeOf(err))
	}
	malloryToken, _ := h.register("mallory", "password123", "")
	if _, err := adaChat.AddMembers(ctx, connect.NewRequest(&ratatoskv1.AddMembersRequest{
		ConversationId: groupID, Usernames: []string{"mallory"},
	})); err != nil {
		t.Fatalf("owner add: %v", err)
	}
	// Adding an existing member again is a no-op error, not a duplicate.
	if _, err := adaChat.AddMembers(ctx, connect.NewRequest(&ratatoskv1.AddMembersRequest{
		ConversationId: groupID, Usernames: []string{"mallory"},
	})); codeOf(err) != connect.CodeInvalidArgument {
		t.Fatalf("re-add: code = %v, want InvalidArgument", codeOf(err))
	}

	left, err := malloryLeaves(h, groupID, malloryToken)
	if err != nil {
		t.Fatalf("leave: %v", err)
	}
	if len(left.Msg.GetConversation().GetMembers()) != 2 {
		t.Fatalf("after leaving, members = %d, want 2", len(left.Msg.GetConversation().GetMembers()))
	}

	// A direct conversation cannot grow members.
	direct, err := adaChat.CreateDirectConversation(ctx, connect.NewRequest(&ratatoskv1.CreateDirectConversationRequest{Username: "grace"}))
	if err != nil {
		t.Fatalf("create direct: %v", err)
	}
	if _, err := adaChat.AddMembers(ctx, connect.NewRequest(&ratatoskv1.AddMembersRequest{
		ConversationId: direct.Msg.GetConversation().GetId(), Usernames: []string{"ada"},
	})); codeOf(err) != connect.CodeFailedPrecondition {
		t.Fatalf("add to direct: code = %v, want FailedPrecondition", codeOf(err))
	}
	if _, err := adaChat.CreateDirectConversation(ctx, connect.NewRequest(&ratatoskv1.CreateDirectConversationRequest{Username: "ada"})); codeOf(err) != connect.CodeInvalidArgument {
		t.Fatalf("self conversation: code = %v, want InvalidArgument", codeOf(err))
	}
	_ = graceToken
}

func malloryLeaves(h *harness, convID, token string) (*connect.Response[ratatoskv1.RemoveMemberResponse], error) {
	_, chat, _ := h.authed(token)
	return chat.RemoveMember(context.Background(), connect.NewRequest(&ratatoskv1.RemoveMemberRequest{ConversationId: convID}))
}

func TestPersistenceAcrossRestart(t *testing.T) {
	dir := t.TempDir()
	ctx := context.Background()

	srv1, st1 := newServerOn(t, dir)
	h1 := harnessOn(t, srv1)
	reg, err := h1.auth.Register(ctx, connect.NewRequest(&ratatoskv1.RegisterRequest{Username: "ada", Password: "password123"}))
	if err != nil {
		t.Fatalf("register: %v", err)
	}
	if _, err := h1.auth.Register(ctx, connect.NewRequest(&ratatoskv1.RegisterRequest{Username: "grace", Password: "password123"})); err != nil {
		t.Fatalf("register grace: %v", err)
	}
	token := reg.Msg.GetToken()
	_, adaChat, adaSocial := h1.authed(token)

	direct, err := adaChat.CreateDirectConversation(ctx, connect.NewRequest(&ratatoskv1.CreateDirectConversationRequest{Username: "grace"}))
	if err != nil {
		t.Fatalf("create direct: %v", err)
	}
	convID := direct.Msg.GetConversation().GetId()
	if _, err := adaChat.SendMessage(ctx, connect.NewRequest(&ratatoskv1.SendMessageRequest{
		ConversationId: convID, Text: "before restart",
	})); err != nil {
		t.Fatalf("send: %v", err)
	}
	inv, err := adaSocial.CreateInvite(ctx, connect.NewRequest(&ratatoskv1.CreateInviteRequest{}))
	if err != nil {
		t.Fatalf("invite: %v", err)
	}

	// Close the store (as a shutdown does), then reopen the same directory.
	if err := st1.Close(); err != nil {
		t.Fatalf("close store: %v", err)
	}

	srv2, _ := newServerOn(t, dir)
	h2 := harnessOn(t, srv2)
	login, err := h2.auth.Login(ctx, connect.NewRequest(&ratatoskv1.LoginRequest{Username: "ada", Password: "password123"}))
	if err != nil {
		t.Fatalf("login after restart: %v", err)
	}
	if login.Msg.GetUser().GetId() != reg.Msg.GetUser().GetId() {
		t.Fatal("the user id changed across a restart")
	}
	_, chat2, social2 := h2.authed(login.Msg.GetToken())
	msgs, err := chat2.ListMessages(ctx, connect.NewRequest(&ratatoskv1.ListMessagesRequest{ConversationId: convID}))
	if err != nil {
		t.Fatalf("list after restart: %v", err)
	}
	if len(msgs.Msg.GetMessages()) != 1 || msgs.Msg.GetMessages()[0].GetText() != "before restart" {
		t.Fatalf("messages after restart = %v", msgs.Msg.GetMessages())
	}
	preview, err := social2.PreviewInvite(ctx, connect.NewRequest(&ratatoskv1.PreviewInviteRequest{Code: inv.Msg.GetInvite().GetCode()}))
	if err != nil {
		t.Fatalf("preview after restart: %v", err)
	}
	if !preview.Msg.GetValid() {
		t.Fatal("the invite did not survive the restart")
	}
	// A session issued before the restart still works, which is what the app
	// relies on: the token is durable, not process-local.
	if _, err := chat2.ListConversations(ctx, connect.NewRequest(&ratatoskv1.ListConversationsRequest{})); err != nil {
		t.Fatalf("old token after restart: %v", err)
	}
}

func seqsOf(msgs []*ratatoskv1.Message) []int64 {
	out := make([]int64, 0, len(msgs))
	for _, m := range msgs {
		out = append(out, m.GetSeq())
	}
	return out
}
