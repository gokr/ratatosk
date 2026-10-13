package httpserver_test

import (
	"context"
	"crypto/rand"
	"crypto/rsa"
	"encoding/base64"
	"encoding/json"
	"io"
	"log/slog"
	"math/big"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"testing"
	"time"

	"connectrpc.com/connect"
	"github.com/golang-jwt/jwt/v5"

	ratatoskv1 "github.com/gokr/ratatosk/server/gen/ratatosk/v1"
	"github.com/gokr/ratatosk/server/gen/ratatosk/v1/ratatoskv1connect"
	"github.com/gokr/ratatosk/server/internal/httpserver"
	"github.com/gokr/ratatosk/server/internal/realtime"
	"github.com/gokr/ratatosk/server/internal/service"
	"github.com/gokr/ratatosk/server/internal/store"
)

// fakeGoogle is enough of Google to drive the whole flow: a key set, an
// authorization endpoint that redirects back with a code, and a token endpoint that
// exchanges it. It is a fake because the real thing cannot be asked to mint a token
// with the wrong audience or to fail on demand.
type fakeGoogle struct {
	key      *rsa.PrivateKey
	kid      string
	clientID string
	server   *httptest.Server
	// subject is the identity the next exchange will claim.
	subject string
	email   string
	name    string
	// tamper, when set, mutates the claims before signing.
	tamper func(jwt.MapClaims)
	// redirectURISeen and verifierSeen record what the exchange received, so the
	// tests can assert PKCE actually happened.
	redirectURISeen string
	verifierSeen    string
}

func newFakeGoogle(t *testing.T, clientID string) *fakeGoogle {
	t.Helper()
	key, err := rsa.GenerateKey(rand.Reader, 2048)
	if err != nil {
		t.Fatalf("key: %v", err)
	}
	g := &fakeGoogle{key: key, kid: "fake-1", clientID: clientID, subject: "google-subject-1"}
	mux := http.NewServeMux()
	mux.HandleFunc("/certs", func(w http.ResponseWriter, r *http.Request) {
		_ = json.NewEncoder(w).Encode(map[string]any{"keys": []map[string]any{{
			"kid": g.kid, "kty": "RSA", "alg": "RS256", "use": "sig",
			"n": base64.RawURLEncoding.EncodeToString(g.key.N.Bytes()),
			"e": base64.RawURLEncoding.EncodeToString(big.NewInt(int64(g.key.E)).Bytes()),
		}}})
	})
	mux.HandleFunc("/token", func(w http.ResponseWriter, r *http.Request) {
		_ = r.ParseForm()
		g.verifierSeen = r.PostForm.Get("code_verifier")
		g.redirectURISeen = r.PostForm.Get("redirect_uri")
		claims := jwt.MapClaims{
			"iss": "https://accounts.google.com", "aud": g.clientID,
			"sub": g.subject, "email": g.email, "email_verified": true, "name": g.name,
			"iat": time.Now().Add(-time.Minute).Unix(), "exp": time.Now().Add(time.Hour).Unix(),
		}
		if g.tamper != nil {
			g.tamper(claims)
		}
		token := jwt.NewWithClaims(jwt.SigningMethodRS256, claims)
		token.Header["kid"] = g.kid
		signed, err := token.SignedString(g.key)
		if err != nil {
			t.Errorf("sign: %v", err)
			return
		}
		_ = json.NewEncoder(w).Encode(map[string]any{"id_token": signed})
	})
	g.server = httptest.NewServer(mux)
	t.Cleanup(g.server.Close)
	return g
}

// googleHarness builds a server wired to the fake Google.
func googleHarness(t *testing.T, g *fakeGoogle) (*harness, *store.Store) {
	t.Helper()
	dir := t.TempDir()
	st, err := store.Open(dir, slog.New(slog.NewTextHandler(io.Discard, nil)))
	if err != nil {
		t.Fatalf("open store: %v", err)
	}
	t.Cleanup(func() { _ = st.Close() })
	hub := realtime.NewHub()
	presence := realtime.NewTracker(st, hub, nil, time.Minute, slog.New(slog.NewTextHandler(io.Discard, nil)))
	cfg := service.DefaultConfig()
	cfg.PublicURL = "http://app.test"
	cfg.GoogleClientID = g.clientID
	services := service.New(st, hub, presence, cfg, slog.New(slog.NewTextHandler(io.Discard, nil)))

	srv := httptest.NewServer(httpserver.New(httpserver.Config{
		Version:        "test",
		Addr:           "127.0.0.1:0",
		PublicURL:      "http://app.test",
		GoogleClientID: g.clientID,
		GoogleJWKSURL:  g.server.URL + "/certs",
		GoogleTokenURL: g.server.URL + "/token",
		GoogleAuthURL:  g.server.URL + "/auth",
		WebDir:         "",
		Log:            slog.New(slog.NewTextHandler(io.Discard, nil)),
	}, st, hub, presence, services))
	t.Cleanup(srv.Close)

	return harnessOn(t, srv), st
}

// startFlow begins a sign-in and returns where Google is about to send the browser.
func startFlow(t *testing.T, h *harness) (state string) {
	t.Helper()
	client := &http.Client{CheckRedirect: func(*http.Request, []*http.Request) error { return http.ErrUseLastResponse }}
	resp, err := client.Get(h.baseURL + "/auth/google/start")
	if err != nil {
		t.Fatalf("start: %v", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusFound {
		t.Fatalf("start status = %d, want 302", resp.StatusCode)
	}
	loc, err := url.Parse(resp.Header.Get("Location"))
	if err != nil {
		t.Fatalf("location: %v", err)
	}
	// The redirect must carry a challenge, never the verifier.
	if loc.Query().Get("code_challenge") == "" || loc.Query().Get("code_challenge_method") != "S256" {
		t.Fatalf("no PKCE challenge on the redirect: %s", loc)
	}
	if loc.Query().Get("code_verifier") != "" {
		t.Fatal("the redirect leaked the PKCE verifier")
	}
	return loc.Query().Get("state")
}

// callback drives the second leg and returns the app redirect it produced.
func callback(t *testing.T, h *harness, state, code string) *url.URL {
	t.Helper()
	client := &http.Client{CheckRedirect: func(*http.Request, []*http.Request) error { return http.ErrUseLastResponse }}
	resp, err := client.Get(h.baseURL + "/auth/google/callback?state=" + url.QueryEscape(state) + "&code=" + url.QueryEscape(code))
	if err != nil {
		t.Fatalf("callback: %v", err)
	}
	defer resp.Body.Close()
	io.Copy(io.Discard, resp.Body)
	if resp.StatusCode != http.StatusFound {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("callback status = %d, body=%s", resp.StatusCode, body)
	}
	loc, err := url.Parse(resp.Header.Get("Location"))
	if err != nil {
		t.Fatalf("callback location: %v", err)
	}
	return loc
}

func TestGoogleSignUpRequiresAnInviteAndAUsername(t *testing.T) {
	g := newFakeGoogle(t, "test-client-id")
	g.subject, g.email, g.name = "sub-1", "goran@example.com", "Göran Krampe"
	h, _ := googleHarness(t, g)
	ctx := context.Background()

	auth := ratatoskv1connect.NewAuthServiceClient(h.srv.Client(), h.baseURL)

	// The config is public, so the sign-in screen can decide whether to show the
	// button before anybody has a token.
	cfgResp, err := auth.GoogleSignInConfig(ctx, connect.NewRequest(&ratatoskv1.GoogleSignInConfigRequest{}))
	if err != nil {
		t.Fatalf("config: %v", err)
	}
	if !cfgResp.Msg.GetEnabled() || cfgResp.Msg.GetClientId() != "test-client-id" {
		t.Fatalf("config = %+v", cfgResp.Msg)
	}
	if !strings.HasSuffix(cfgResp.Msg.GetRedirectUri(), "/auth/google/callback") {
		t.Errorf("redirect uri = %q", cfgResp.Msg.GetRedirectUri())
	}

	// A first sign-in: verified, but not an account. It comes back pending.
	pending := callback(t, h, startFlow(t, h), "auth-code-1")
	pendingToken := pending.Query().Get("google_pending")
	if pendingToken == "" {
		t.Fatalf("expected a pending registration, got %s", pending)
	}
	if got := pending.Query().Get("google_suggested_username"); got != "goran-krampe" {
		t.Errorf("suggested username = %q, want goran-krampe", got)
	}

	// No invitation: refused, and the pending identity is handed back so the
	// attempt can continue.
	if _, err := auth.FinishGoogleSignUp(ctx, connect.NewRequest(&ratatoskv1.FinishGoogleSignUpRequest{
		PendingToken: pendingToken, Username: "gokr",
	})); err == nil {
		t.Fatal("an account was created with no invitation")
	}
	if _, err := auth.FinishGoogleSignUp(ctx, connect.NewRequest(&ratatoskv1.FinishGoogleSignUpRequest{
		PendingToken: pendingToken, Username: "gokr", InviteCode: "nosuchcode",
	})); err == nil {
		t.Fatal("an account was created with a bogus invitation")
	}

	// Now with a real invitation. It must come from an existing account, so one is
	// made the ordinary way.
	inviterToken, _ := h.register("ada", "password123", "Ada")
	_, _, social := h.authed(inviterToken)
	inv, err := social.CreateInvite(ctx, connect.NewRequest(&ratatoskv1.CreateInviteRequest{MaxUses: 1}))
	if err != nil {
		t.Fatalf("invite: %v", err)
	}
	code := inv.Msg.GetInvite().GetCode()

	done, err := auth.FinishGoogleSignUp(ctx, connect.NewRequest(&ratatoskv1.FinishGoogleSignUpRequest{
		PendingToken: pendingToken, Username: "gokr", DisplayName: "Göran", InviteCode: code,
	}))
	if err != nil {
		t.Fatalf("finish: %v", err)
	}
	if done.Msg.GetToken() == "" || done.Msg.GetUser().GetUsername() != "gokr" {
		t.Fatalf("finish response = %+v", done.Msg)
	}

	// The pending token is single-use: replaying it must not create a second account.
	if _, err := auth.FinishGoogleSignUp(ctx, connect.NewRequest(&ratatoskv1.FinishGoogleSignUpRequest{
		PendingToken: pendingToken, Username: "gokr2", InviteCode: code,
	})); err == nil {
		t.Fatal("a pending token was reused")
	}

	// A second sign-in with the same Google identity is a sign-in, not a new
	// registration — and does not need an invitation, because the account exists.
	again := callback(t, h, startFlow(t, h), "auth-code-2")
	if again.Query().Get("google_token") == "" {
		t.Fatalf("a linked identity did not sign in: %s", again)
	}
	if again.Query().Get("google_pending") != "" {
		t.Error("a linked identity was asked to register again")
	}

	// Sign-in methods reflect what the account has: Google only, no password.
	authed := ratatoskv1connect.NewAuthServiceClient(h.srv.Client(), h.baseURL,
		connect.WithInterceptors(bearerInterceptor{token: again.Query().Get("google_token")}))
	methods, err := authed.SignInMethods(ctx, connect.NewRequest(&ratatoskv1.SignInMethodsRequest{}))
	if err != nil {
		t.Fatalf("methods: %v", err)
	}
	if len(methods.Msg.GetMethods()) != 1 || methods.Msg.GetMethods()[0] != "google" {
		t.Errorf("methods = %v, want [google]", methods.Msg.GetMethods())
	}
	if methods.Msg.GetGoogleEmail() != "goran@example.com" {
		t.Errorf("google email = %q", methods.Msg.GetGoogleEmail())
	}
}

// The whole point of PKCE: the verifier stays server-side and is used in the
// exchange. If it were never sent, Google would refuse the exchange in production.
func TestGoogleFlowUsesPKCE(t *testing.T) {
	g := newFakeGoogle(t, "test-client-id")
	g.subject, g.email = "sub-pkce", "pkce@example.com"
	h, _ := googleHarness(t, g)

	callback(t, h, startFlow(t, h), "auth-code-pkce")
	if g.verifierSeen == "" {
		t.Fatal("the code exchange sent no PKCE verifier")
	}
	if g.redirectURISeen != "http://app.test/auth/google/callback" {
		t.Errorf("exchange redirect_uri = %q", g.redirectURISeen)
	}
}

// A state that was never issued, or is replayed, must not produce a sign-in.
func TestGoogleCallbackRejectsBadState(t *testing.T) {
	g := newFakeGoogle(t, "test-client-id")
	h, _ := googleHarness(t, g)

	loc := callback(t, h, "not-a-real-state", "some-code")
	if loc.Query().Get("google_error") == "" {
		t.Fatal("a forged state produced a result")
	}
	if loc.Query().Get("google_pending") != "" || loc.Query().Get("google_token") != "" {
		t.Fatal("a forged state produced a token")
	}

	// Replaying a used state is refused too.
	state := startFlow(t, h)
	callback(t, h, state, "code-a")
	replay := callback(t, h, state, "code-b")
	if replay.Query().Get("google_token") != "" || replay.Query().Get("google_pending") != "" {
		t.Fatal("a replayed state produced a result")
	}
}

// A token Google would not mint for us must not sign anyone in.
func TestGoogleCallbackRejectsAWrongAudienceToken(t *testing.T) {
	g := newFakeGoogle(t, "test-client-id")
	g.tamper = func(c jwt.MapClaims) { c["aud"] = "someone-elses-client" }
	h, _ := googleHarness(t, g)

	loc := callback(t, h, startFlow(t, h), "code")
	if loc.Query().Get("google_pending") != "" || loc.Query().Get("google_token") != "" {
		t.Fatal("a token for another audience produced a result")
	}
	if loc.Query().Get("google_error") == "" {
		t.Error("no error was reported to the app")
	}
}

// Cancelling at Google's consent screen is a normal outcome, not a failure to log.
func TestGoogleCallbackHandlesCancellation(t *testing.T) {
	g := newFakeGoogle(t, "test-client-id")
	h, _ := googleHarness(t, g)

	client := &http.Client{CheckRedirect: func(*http.Request, []*http.Request) error { return http.ErrUseLastResponse }}
	state := startFlow(t, h)
	resp, err := client.Get(h.baseURL + "/auth/google/callback?error=access_denied&state=" + state)
	if err != nil {
		t.Fatalf("callback: %v", err)
	}
	defer resp.Body.Close()
	loc, _ := url.Parse(resp.Header.Get("Location"))
	if loc.Query().Get("google_error") == "" {
		t.Fatal("cancellation was not reported to the app")
	}
}

// With no client id configured the flow must refuse rather than half-work.
func TestGoogleDisabledWhenUnconfigured(t *testing.T) {
	h := newHarness(t)
	ctx := context.Background()
	auth := ratatoskv1connect.NewAuthServiceClient(h.srv.Client(), h.baseURL)

	cfg, err := auth.GoogleSignInConfig(ctx, connect.NewRequest(&ratatoskv1.GoogleSignInConfigRequest{}))
	if err != nil {
		t.Fatalf("config: %v", err)
	}
	if cfg.Msg.GetEnabled() {
		t.Error("an unconfigured server reported Google sign-in as enabled")
	}

	client := &http.Client{CheckRedirect: func(*http.Request, []*http.Request) error { return http.ErrUseLastResponse }}
	resp, err := client.Get(h.baseURL + "/auth/google/start")
	if err != nil {
		t.Fatalf("start: %v", err)
	}
	defer resp.Body.Close()
	loc, _ := url.Parse(resp.Header.Get("Location"))
	if loc.Query().Get("google_error") == "" {
		t.Error("an unconfigured server started a sign-in")
	}
}

// Connecting Google to an account that already exists — the case a person with a
// password account hits, and which signing in alone can never do.
func TestGoogleLinkToExistingAccount(t *testing.T) {
	g := newFakeGoogle(t, "test-client-id")
	g.subject, g.email, g.name = "link-subject", "gokr@example.com", "Göran"
	h, _ := googleHarness(t, g)
	ctx := context.Background()

	// An account made the ordinary way, with a password.
	token, _ := h.register("gokr", "password123", "Göran")

	auth := ratatoskv1connect.NewAuthServiceClient(h.srv.Client(), h.baseURL,
		connect.WithInterceptors(bearerInterceptor{token: token}))
	link, err := auth.GoogleLinkUrl(ctx, connect.NewRequest(&ratatoskv1.GoogleLinkUrlRequest{}))
	if err != nil {
		t.Fatalf("link url: %v", err)
	}
	if !strings.HasSuffix(link.Msg.GetUrl(), "/auth/google/link") {
		t.Fatalf("link url = %q", link.Msg.GetUrl())
	}

	// Before connecting: password only.
	before, err := auth.SignInMethods(ctx, connect.NewRequest(&ratatoskv1.SignInMethodsRequest{}))
	if err != nil {
		t.Fatalf("methods: %v", err)
	}
	if before.Msg.GetMethods()[0] != "password" || len(before.Msg.GetMethods()) != 1 {
		t.Fatalf("methods before = %v", before.Msg.GetMethods())
	}

	// The link flow: start (authenticated), then the callback. The returned URL is
	// absolute (PublicURL), which is not resolvable here, so the handler is reached
	// on the test server with the same bearer token.
	client := &http.Client{CheckRedirect: func(*http.Request, []*http.Request) error { return http.ErrUseLastResponse }}
	startReq, _ := http.NewRequest(http.MethodGet, h.baseURL+"/auth/google/link", nil)
	startReq.Header.Set("Authorization", "Bearer "+token)
	startResp, err := client.Do(startReq)
	if err != nil {
		t.Fatalf("start: %v", err)
	}
	io.Copy(io.Discard, startResp.Body)
	startResp.Body.Close()
	consent, err := url.Parse(startResp.Header.Get("Location"))
	if err != nil {
		t.Fatalf("consent url: %v", err)
	}
	if consent.Query().Get("google_error") != "" {
		t.Fatalf("link start refused: %s", consent)
	}
	t.Logf("consent host=%s path=%s state=%q challenge=%q", consent.Host, consent.Path, consent.Query().Get("state"), consent.Query().Get("code_challenge"))
	cbResp, err := client.Get(h.baseURL + "/auth/google/callback?state=" +
		url.QueryEscape(consent.Query().Get("state")) + "&code=link-code")
	if err != nil {
		t.Fatalf("callback: %v", err)
	}
	io.Copy(io.Discard, cbResp.Body)
	cbResp.Body.Close()
	done, _ := url.Parse(cbResp.Header.Get("Location"))
	if done.Query().Get("google_linked") != "1" {
		t.Fatalf("linking did not succeed: %s (err=%q)", done, done.Query().Get("google_link_error"))
	}
	// The callback must not have issued a session: linking is not signing in.
	if done.Query().Get("google_token") != "" || done.Query().Get("google_pending") != "" {
		t.Fatal("linking produced a session or a registration")
	}

	// Both ways in, now.
	after, err := auth.SignInMethods(ctx, connect.NewRequest(&ratatoskv1.SignInMethodsRequest{}))
	if err != nil {
		t.Fatalf("methods: %v", err)
	}
	if !contains(after.Msg.GetMethods(), "password") || !contains(after.Msg.GetMethods(), "google") {
		t.Fatalf("methods after = %v", after.Msg.GetMethods())
	}
	if after.Msg.GetGoogleEmail() != "gokr@example.com" {
		t.Errorf("connected email = %q", after.Msg.GetGoogleEmail())
	}

	// Signing in with Google now reaches *that* account, and asks for no invitation.
	signedIn := callback(t, h, startFlow(t, h), "code-after-link")
	if signedIn.Query().Get("google_token") == "" {
		t.Fatalf("the connected identity did not sign in: %s", signedIn)
	}
	linkedAuth := ratatoskv1connect.NewAuthServiceClient(h.srv.Client(), h.baseURL,
		connect.WithInterceptors(bearerInterceptor{token: signedIn.Query().Get("google_token")}))
	me, err := linkedAuth.GetMe(ctx, connect.NewRequest(&ratatoskv1.GetMeRequest{}))
	if err != nil {
		t.Fatalf("getMe: %v", err)
	}
	if me.Msg.GetUser().GetUsername() != "gokr" {
		t.Errorf("signed in as %q, want gokr", me.Msg.GetUser().GetUsername())
	}

	// Disconnecting is allowed, because the password is still a way in.
	if _, err := auth.UnlinkGoogle(ctx, connect.NewRequest(&ratatoskv1.UnlinkGoogleRequest{})); err != nil {
		t.Fatalf("unlink: %v", err)
	}
	final, err := auth.SignInMethods(ctx, connect.NewRequest(&ratatoskv1.SignInMethodsRequest{}))
	if err != nil {
		t.Fatalf("methods: %v", err)
	}
	if contains(final.Msg.GetMethods(), "google") {
		t.Error("google is still connected after unlinking")
	}
}

// The refusal that stops linking from being a takeover: an identity already connected
// to somebody else is never moved to the caller's account.
func TestGoogleLinkRefusesAnIdentityInUseElsewhere(t *testing.T) {
	g := newFakeGoogle(t, "test-client-id")
	h, _ := googleHarness(t, g)
	ctx := context.Background()

	// Ada registers an invitation, and a second person signs up with Google using it.
	adaToken, _ := h.register("ada", "password123", "Ada")
	_, _, adaSocial := h.authed(adaToken)
	inv, err := adaSocial.CreateInvite(ctx, connect.NewRequest(&ratatoskv1.CreateInviteRequest{}))
	if err != nil {
		t.Fatalf("invite: %v", err)
	}
	g.subject, g.email, g.name = "shared-identity", "shared@example.com", "Shared"
	auth := ratatoskv1connect.NewAuthServiceClient(h.srv.Client(), h.baseURL)
	pending := callback(t, h, startFlow(t, h), "code-1").Query().Get("google_pending")
	if _, err := auth.FinishGoogleSignUp(ctx, connect.NewRequest(&ratatoskv1.FinishGoogleSignUpRequest{
		PendingToken: pending, Username: "grace", InviteCode: inv.Msg.GetInvite().GetCode(),
	})); err != nil {
		t.Fatalf("finish: %v", err)
	}

	// Now somebody else — a different Ratatosk account — tries to connect the *same*
	// Google identity to themselves.
	malloryToken, _ := h.register("mallory", "password123", "Mallory")
	mallory := ratatoskv1connect.NewAuthServiceClient(h.srv.Client(), h.baseURL,
		connect.WithInterceptors(bearerInterceptor{token: malloryToken}))
	if _, err := mallory.GoogleLinkUrl(ctx, connect.NewRequest(&ratatoskv1.GoogleLinkUrlRequest{})); err != nil {
		t.Fatalf("link url: %v", err)
	}
	client := &http.Client{CheckRedirect: func(*http.Request, []*http.Request) error { return http.ErrUseLastResponse }}
	startReq, _ := http.NewRequest(http.MethodGet, h.baseURL+"/auth/google/link", nil)
	startReq.Header.Set("Authorization", "Bearer "+malloryToken)
	startResp, _ := client.Do(startReq)
	io.Copy(io.Discard, startResp.Body)
	startResp.Body.Close()
	consent, _ := url.Parse(startResp.Header.Get("Location"))
	cbResp, _ := client.Get(h.baseURL + "/auth/google/callback?state=" +
		url.QueryEscape(consent.Query().Get("state")) + "&code=stolen")
	io.Copy(io.Discard, cbResp.Body)
	cbResp.Body.Close()
	result, _ := url.Parse(cbResp.Header.Get("Location"))
	if result.Query().Get("google_linked") == "1" {
		t.Fatal("an identity already connected elsewhere was moved")
	}
	if result.Query().Get("google_link_error") == "" {
		t.Fatal("the refusal was not explained to the person")
	}

	// And Mallory still has only a password: nothing was attached.
	malloryMethods, err := mallory.SignInMethods(ctx, connect.NewRequest(&ratatoskv1.SignInMethodsRequest{}))
	if err != nil {
		t.Fatalf("methods: %v", err)
	}
	if contains(malloryMethods.Msg.GetMethods(), "google") {
		t.Error("the identity was attached anyway")
	}
}

// An account whose only way in is Google must not be able to disconnect it.
func TestUnlinkRefusedWhenItIsTheOnlyWayIn(t *testing.T) {
	g := newFakeGoogle(t, "test-client-id")
	g.subject, g.email, g.name = "only-way", "only@example.com", "Only"
	h, _ := googleHarness(t, g)
	ctx := context.Background()

	adaToken, _ := h.register("ada", "password123", "Ada")
	_, _, adaSocial := h.authed(adaToken)
	inv, _ := adaSocial.CreateInvite(ctx, connect.NewRequest(&ratatoskv1.CreateInviteRequest{}))
	auth := ratatoskv1connect.NewAuthServiceClient(h.srv.Client(), h.baseURL)
	pending := callback(t, h, startFlow(t, h), "code").Query().Get("google_pending")
	finish, err := auth.FinishGoogleSignUp(ctx, connect.NewRequest(&ratatoskv1.FinishGoogleSignUpRequest{
		PendingToken: pending, Username: "googleonly", InviteCode: inv.Msg.GetInvite().GetCode(),
	}))
	if err != nil {
		t.Fatalf("finish: %v", err)
	}

	only := ratatoskv1connect.NewAuthServiceClient(h.srv.Client(), h.baseURL,
		connect.WithInterceptors(bearerInterceptor{token: finish.Msg.GetToken()}))
	if _, err := only.UnlinkGoogle(ctx, connect.NewRequest(&ratatoskv1.UnlinkGoogleRequest{})); err == nil {
		t.Fatal("the only way into the account was removed")
	}
	// Still connected, and still usable.
	methods, err := only.SignInMethods(ctx, connect.NewRequest(&ratatoskv1.SignInMethodsRequest{}))
	if err != nil {
		t.Fatalf("methods: %v", err)
	}
	if !contains(methods.Msg.GetMethods(), "google") {
		t.Error("the account lost its only sign-in method")
	}
}

func contains(list []string, want string) bool {
	for _, item := range list {
		if item == want {
			return true
		}
	}
	return false
}
