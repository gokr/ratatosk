// Package httpserver exposes the Connect services plus the few plain HTTP
// endpoints the app needs: attachment download, the invite landing page and a
// health check.
package httpserver

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"html/template"
	"log/slog"
	"net/http"
	"os"
	"path"
	"path/filepath"
	"strings"
	"time"

	"connectrpc.com/connect"
	"golang.org/x/net/http2"
	"golang.org/x/net/http2/h2c"

	"github.com/gokr/ratatosk/server/gen/ratatosk/v1/ratatoskv1connect"
	"github.com/gokr/ratatosk/server/internal/auth"
	"github.com/gokr/ratatosk/server/internal/googleid"
	"github.com/gokr/ratatosk/server/internal/push"
	"github.com/gokr/ratatosk/server/internal/realtime"
	"github.com/gokr/ratatosk/server/internal/service"
	"github.com/gokr/ratatosk/server/internal/store"
)

// Config is everything the HTTP layer needs to know.
type Config struct {
	Version string
	Push    *push.Worker
	Addr    string
	// PublicURL is the origin clients should use, for links in the landing page.
	PublicURL string
	// CORSOrigins lists allowed browser origins; "*" allows any. Only needed
	// when the web app is served from a *different* origin than this API, e.g.
	// `flutter run -d web-server` during development. Serving the built web app
	// from WebDir (the default) needs no CORS at all.
	CORSOrigins []string
	// DeepLinkScheme is the custom scheme the mobile apps register, e.g.
	// "ratatosk" in ratatosk://join/CODE.
	DeepLinkScheme string
	// WebDir is a built Flutter web app (app/build/web). When it exists it is
	// served from /, which makes one url the whole product: the app, its API,
	// attachment bytes and the invitation landing page all on one origin.
	WebDir string
	// GoogleClientID and GoogleClientSecret enable Google sign-in. Empty client id
	// means the button is hidden and no token is accepted anywhere.
	GoogleClientID     string
	GoogleClientSecret string
	// GoogleJWKSURL overrides where Google's signing keys are read from. Empty
	// means Google's own endpoint; set it behind a restrictive network or in tests.
	GoogleJWKSURL string
	// GoogleTokenURL and GoogleAuthURL override the two endpoints of the redirect
	// flow, for the same reasons.
	GoogleTokenURL string
	GoogleAuthURL  string
	Log            *slog.Logger
}

// Server wires the Connect handlers onto an HTTP mux.
type Server struct {
	cfg      Config
	st       *store.Store
	hub      *realtime.Hub
	presence *realtime.Tracker
	services *service.Services
	log      *slog.Logger
	handler  http.Handler
	// google verifies ID tokens; unavailable unless a client id is configured.
	google     *googleid.Verifier
	httpClient *http.Client
}

// New builds the server. The returned *Server is an http.Handler.
func New(cfg Config, st *store.Store, hub *realtime.Hub, presence *realtime.Tracker, services *service.Services) *Server {
	if cfg.Log == nil {
		cfg.Log = slog.Default()
	}
	if cfg.DeepLinkScheme == "" {
		cfg.DeepLinkScheme = "ratatosk"
	}
	if cfg.GoogleClientID != "" && cfg.GoogleClientSecret == "" {
		// Google's *Web application* clients require the secret for the code
		// exchange — PKCE does not replace it, it only binds the exchange to the
		// server that started it. So a client id without a secret is a flow that can
		// never complete: every attempt would reach Google and come back refused,
		// which is exactly what happened once and cost a debugging session.
		//
		// Reported loudly and treated as "not configured", so the button is hidden
		// rather than sending people into a dead end. Refusing to boot would take the
		// whole service down for one optional feature.
		cfg.Log.Error("Google sign-in is disabled: RATATOSK_GOOGLE_CLIENT_SECRET is not set",
			"detail", "Google requires the client secret for the authorization-code exchange; set it and restart")
		cfg.GoogleClientID = ""
	}
	s := &Server{
		cfg: cfg, st: st, hub: hub, presence: presence, services: services, log: cfg.Log,
		// Timeout rather than the default client: every call here is to Google, and
		// a hung exchange must not hold a request open indefinitely.
		httpClient: &http.Client{Timeout: 15 * time.Second},
		google:     googleid.NewWithJWKSURL(cfg.GoogleClientID, cfg.GoogleJWKSURL, nil),
	}
	s.handler = s.build()
	return s
}

// ServeHTTP implements http.Handler.
func (s *Server) ServeHTTP(w http.ResponseWriter, r *http.Request) { s.handler.ServeHTTP(w, r) }

// build assembles the mux: Connect procedures, attachments, invite pages.
func (s *Server) build() http.Handler {
	mux := http.NewServeMux()

	// The auth interceptor resolves the bearer token into an identity that the
	// service handlers read from the context.
	interceptors := connect.WithInterceptors(newAuthInterceptor(s.st, s.presence))

	authPath, authHandler := ratatoskv1connect.NewAuthServiceHandler(s.services.Auth, interceptors)
	chatPath, chatHandler := ratatoskv1connect.NewChatServiceHandler(s.services.Chat, interceptors)
	socialPath, socialHandler := ratatoskv1connect.NewSocialServiceHandler(s.services.Social, interceptors)
	keysPath, keysHandler := ratatoskv1connect.NewKeyServiceHandler(s.services.Keys, interceptors)
	mux.Handle(authPath, authHandler)
	mux.Handle(chatPath, chatHandler)
	mux.Handle(socialPath, socialHandler)
	mux.Handle(keysPath, keysHandler)

	mux.HandleFunc("GET /api/push/config", s.servePushConfig)
	mux.HandleFunc("POST /api/push/subscriptions", s.servePushSubscription)
	mux.HandleFunc("DELETE /api/push/subscriptions", s.servePushSubscription)
	mux.HandleFunc("/files/{id}", s.serveAttachment)
	// The path wildcards keep the code on one segment: a request such as
	// /join/a/b can never be mistaken for an invite code containing a slash.
	mux.HandleFunc("/join/{code}", s.serveInvitePage)
	mux.HandleFunc("/invite/{code}", s.serveInviteJSON)
	// Google sign-in: the redirect out and the callback back. Both are plain HTTP
	// because the browser is the client, and both are unauthenticated by necessity —
	// signing in is what they are for.
	mux.HandleFunc("GET /auth/google/start", s.serveGoogleStart)
	// Linking is a separate endpoint on purpose: its callback attaches the identity
	// to the account that started it instead of issuing a session, so the two URLs
	// must not be interchangeable.
	mux.HandleFunc("GET /auth/google/link", s.serveGoogleLinkStart)
	mux.HandleFunc("GET /auth/google/callback", s.serveGoogleCallback)
	mux.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
		stats := s.st.Stats()
		writeJSON(w, http.StatusOK, map[string]any{
			"status":        "ok",
			"version":       s.cfg.Version,
			"users":         stats.Users,
			"conversations": stats.Conversations,
			"messages":      stats.Messages,
		})
	})
	mux.HandleFunc("/", s.serveRoot)

	var h http.Handler = mux
	// h2c lets the app use HTTP/2 (and therefore gRPC) without TLS in
	// development; with TLS, net/http speaks HTTP/2 natively.
	h = h2c.NewHandler(h, &http2.Server{})
	h = s.withCORS(h)
	h = s.withLogging(h)
	return h
}

// --- middleware ----------------------------------------------------------

// withCORS answers preflights and adds the headers a browser client needs.
// Flutter web calls from a different origin than the server, so this is the
// difference between "works in the browser" and "mysteriously fails".
func (s *Server) withCORS(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		origin := r.Header.Get("Origin")
		if origin != "" && s.originAllowed(origin) {
			w.Header().Set("Access-Control-Allow-Origin", origin)
			w.Header().Set("Vary", "Origin")
			w.Header().Set("Access-Control-Allow-Credentials", "true")
			w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
			// Connect and gRPC-Web put metadata in headers the browser hides by
			// default; without these the client cannot read trailers.
			w.Header().Set("Access-Control-Allow-Headers",
				"Content-Type, Authorization, Connect-Protocol-Version, Connect-Timeout-Ms, X-Grpc-Web, X-User-Agent, Grpc-Timeout, X-Grpc-Timeout")
			w.Header().Set("Access-Control-Expose-Headers",
				"Content-Type, Grpc-Status, Grpc-Message, Grpc-Status-Details-Bin, Connect-Protocol-Version, Trailer")
			w.Header().Set("Access-Control-Max-Age", "600")
		}
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		next.ServeHTTP(w, r)
	})
}

func (s *Server) originAllowed(origin string) bool {
	for _, allowed := range s.cfg.CORSOrigins {
		if allowed == "*" || strings.EqualFold(allowed, origin) {
			return true
		}
	}
	return false
}

// withLogging records failures without drowning the log in per-message
// chatter: pushes arrive constantly in a busy conversation.
func (s *Server) withLogging(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Streaming RPCs are long-lived by design; do not time or log them as
		// if they were requests.
		if strings.HasSuffix(r.URL.Path, "/Subscribe") {
			next.ServeHTTP(w, r)
			return
		}
		rec := &statusRecorder{ResponseWriter: w, status: http.StatusOK}
		start := time.Now()
		next.ServeHTTP(rec, r)
		if rec.status >= 400 {
			s.log.Info("request failed",
				"method", r.Method, "path", r.URL.Path,
				"status", rec.status, "duration", time.Since(start).Round(time.Millisecond))
		}
	})
}

type statusRecorder struct {
	http.ResponseWriter
	status int
}

func (r *statusRecorder) WriteHeader(code int) {
	r.status = code
	r.ResponseWriter.WriteHeader(code)
}

// --- auth interceptor ----------------------------------------------------

// publicProcedures may be called without a token. Everything else requires one.
//
// Logout is here deliberately: revoking the token you present is harmless
// when you have none, and a client whose session just expired must still be
// able to clear it without handling an error.
var publicProcedures = map[string]bool{
	ratatoskv1connect.AuthServiceRegisterProcedure:        true,
	ratatoskv1connect.AuthServiceLoginProcedure:           true,
	ratatoskv1connect.AuthServiceLogoutProcedure:          true,
	ratatoskv1connect.SocialServicePreviewInviteProcedure: true,
	// Signing in with Google is done by the browser before it has a token; the
	// pending token it comes back with is what authorizes finishing the sign-up.
	ratatoskv1connect.AuthServiceGoogleSignInConfigProcedure: true,
	ratatoskv1connect.AuthServiceFinishGoogleSignUpProcedure: true,
}

type authInterceptor struct {
	st       *store.Store
	presence *realtime.Tracker
}

func newAuthInterceptor(st *store.Store, presence *realtime.Tracker) connect.Interceptor {
	return &authInterceptor{st: st, presence: presence}
}

func (a *authInterceptor) WrapUnary(next connect.UnaryFunc) connect.UnaryFunc {
	return func(ctx context.Context, req connect.AnyRequest) (connect.AnyResponse, error) {
		ctx, err := a.authenticate(ctx, req.Header(), req.Spec().Procedure)
		if err != nil {
			return nil, err
		}
		return next(ctx, req)
	}
}

func (a *authInterceptor) WrapStreamingHandler(next connect.StreamingHandlerFunc) connect.StreamingHandlerFunc {
	return func(ctx context.Context, conn connect.StreamingHandlerConn) error {
		ctx, err := a.authenticate(ctx, conn.RequestHeader(), conn.Spec().Procedure)
		if err != nil {
			return err
		}
		return next(ctx, conn)
	}
}

// WrapStreamingClient exists only because connect.Interceptor covers both
// sides of the wire; this server never acts as a client.
func (a *authInterceptor) WrapStreamingClient(next connect.StreamingClientFunc) connect.StreamingClientFunc {
	return next
}

// authenticate resolves the bearer token. A missing or invalid token is only
// fatal for non-public procedures: public ones see an anonymous caller, which
// is what makes the invite landing page work before sign-up.
func (a *authInterceptor) authenticate(ctx context.Context, header http.Header, procedure string) (context.Context, error) {
	token := bearerToken(header)
	if token == "" {
		if publicProcedures[procedure] {
			return ctx, nil
		}
		return ctx, connect.NewError(connect.CodeUnauthenticated, errors.New("sign in to continue"))
	}
	session, err := a.st.SessionByToken(token, time.Now())
	if err != nil {
		if publicProcedures[procedure] {
			return ctx, nil
		}
		return ctx, connect.NewError(connect.CodeUnauthenticated, errors.New("your session expired; sign in again"))
	}
	user, err := a.st.UserByID(session.UserID)
	if err != nil {
		return ctx, connect.NewError(connect.CodeUnauthenticated, errors.New("this account no longer exists"))
	}
	// Activity drives "online" vs "away"; cheap enough for every call.
	a.st.TouchUser(user.ID, time.Now())
	if a.presence != nil {
		a.presence.Active(user.ID)
	}

	// A client names the device key it holds so key-envelope calls can be
	// scoped to that device. A key id that is unknown, revoked, or belongs to
	// somebody else is ignored rather than trusted: the request is still
	// authenticated as the user, and the calls that need a device key say so.
	if deviceID := header.Get(deviceKeyHeader); deviceID != "" {
		if key, err := a.st.DeviceKeyByID(deviceID); err == nil && !key.Revoked && key.UserID == user.ID {
			a.st.TouchDeviceKey(deviceID, time.Now())
			ctx = auth.WithDeviceKey(ctx, deviceID)
		}
	}
	return auth.WithIdentity(ctx, user, token), nil
}

// deviceKeyHeader is how a client names the device key it holds. It is a plain
// header rather than part of the token so one login can serve several devices.
const deviceKeyHeader = "X-Ratatosk-Device-Key"

func bearerToken(header http.Header) string {
	raw := header.Get("Authorization")
	if raw == "" {
		return ""
	}
	if len(raw) > 7 && strings.EqualFold(raw[:7], "bearer ") {
		return strings.TrimSpace(raw[7:])
	}
	return strings.TrimSpace(raw)
}

// --- attachments ---------------------------------------------------------

// serveAttachment streams an attachment's bytes. A browser <img> cannot send an
// Authorization header, so a token in the query string is accepted too.
func (s *Server) serveAttachment(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	if id == "" {
		http.Error(w, "not found", http.StatusNotFound)
		return
	}
	token := r.URL.Query().Get("token")
	if token == "" {
		token = bearerToken(r.Header)
	}
	if token == "" {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}
	if _, err := s.st.SessionByToken(token, time.Now()); err != nil {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}
	att, err := s.st.AttachmentByID(id)
	if err != nil {
		http.Error(w, "not found", http.StatusNotFound)
		return
	}
	file, err := os.Open(s.st.AttachmentPath(id))
	if err != nil {
		http.Error(w, "not found", http.StatusNotFound)
		return
	}
	defer file.Close()

	contentType := att.ContentType
	if contentType == "" {
		contentType = "application/octet-stream"
	}
	disposition := "attachment"
	if strings.HasPrefix(contentType, "image/") || strings.HasPrefix(contentType, "video/") {
		disposition = "inline"
	}
	w.Header().Set("Content-Type", contentType)
	w.Header().Set("Content-Disposition", fmt.Sprintf("%s; filename=%q", disposition, att.Filename))
	w.Header().Set("Cache-Control", "private, max-age=86400")
	// Content is immutable per id, which is what makes the long cache safe.
	http.ServeContent(w, r, att.Filename, att.CreatedAt, file)
}

// --- invite landing page -------------------------------------------------

type invitePageData struct {
	AppName string
	Valid   bool
	// Reason is the machine-readable verdict: "", "unknown", "revoked",
	// "expired", "exhausted". ReasonText is the same thing said to a person.
	Reason      string
	ReasonText  string
	Code        string
	InviterName string
	InviterUser string
	AvatarURL   string
	// DeepLink is typed template.URL because html/template refuses to emit an
	// href for a scheme it does not recognise, which would silently turn the
	// "Open in the app" button into a dead link. It is built here from the
	// configured scheme plus the server-generated invite code.
	DeepLink    template.URL
	AppStoreURL string
	PlayURL     string
	ExpiresText string
	UsesText    string
}

// inviteReasonText turns the machine reason into a sentence for the page.
func inviteReasonText(reason string) string {
	switch reason {
	case "revoked":
		return "This invitation was cancelled by the person who sent it."
	case "expired":
		return "This invitation has expired."
	case "exhausted":
		return "This invitation has already been used."
	case "unknown":
		return "We could not find that invitation."
	default:
		return "This invitation is not available."
	}
}

// inviteData is the single interpretation of an invite for both the landing
// page and the JSON preview, so the two can never disagree.
func (s *Server) inviteData(code string) invitePageData {
	code = strings.ToLower(strings.Trim(code, "/"))
	data := invitePageData{
		AppName:  "Ratatosk",
		Code:     code,
		DeepLink: template.URL(s.cfg.DeepLinkScheme + "://join/" + code),
	}
	inv, err := s.st.InviteByCode(code)
	if err != nil {
		data.Reason = "unknown"
		data.ReasonText = inviteReasonText(data.Reason)
		return data
	}
	if reason := inviteReason(inv); reason != "" {
		data.Reason = reason
		data.ReasonText = inviteReasonText(reason)
		return data
	}
	data.Valid = true
	if inviter, err := s.st.UserByID(inv.InviterID); err == nil {
		data.InviterName = inviter.DisplayName
		data.InviterUser = "@" + inviter.Username
		if inviter.Avatar != "" {
			data.AvatarURL = "/files/" + inviter.Avatar
		}
	}
	if !inv.ExpiresAt.IsZero() {
		data.ExpiresText = inv.ExpiresAt.Format("2 January 2006")
	}
	switch {
	case inv.MaxUses <= 0:
		data.UsesText = "This link can be used any number of times."
	case inv.MaxUses-inv.Uses == 1:
		data.UsesText = "One use left on this link."
	default:
		data.UsesText = fmt.Sprintf("%d uses left on this link.", inv.MaxUses-inv.Uses)
	}
	return data
}

// inviteReason returns "" when the invite can still be redeemed, or the
// machine-readable reason it cannot.
func inviteReason(inv *store.Invite) string {
	switch {
	case inv.Revoked:
		return "revoked"
	case !inv.ExpiresAt.IsZero() && time.Now().After(inv.ExpiresAt):
		return "expired"
	case inv.MaxUses > 0 && inv.Uses >= inv.MaxUses:
		return "exhausted"
	default:
		return ""
	}
}

func (s *Server) serveInvitePage(w http.ResponseWriter, r *http.Request) {
	data := s.inviteData(r.PathValue("code"))
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	w.Header().Set("Cache-Control", "no-store")
	if err := inviteTemplate.Execute(w, data); err != nil {
		s.log.Error("invite page render failed", "err", err)
	}
}

// serveInviteJSON is the same preview for scripts and tests: the app's invite
// sheet and a shell both need to answer "is this link still good?".
func (s *Server) serveInviteJSON(w http.ResponseWriter, r *http.Request) {
	data := s.inviteData(r.PathValue("code"))
	writeJSON(w, http.StatusOK, map[string]any{
		"code":       data.Code,
		"valid":      data.Valid,
		"reason":     data.Reason,
		"detail":     data.ReasonText,
		"inviter":    data.InviterName,
		"username":   strings.TrimPrefix(data.InviterUser, "@"),
		"expiresOn":  data.ExpiresText,
		"usesNotice": data.UsesText,
		"deepLink":   data.DeepLink,
	})
}

// serveRoot serves the built web app when there is one, and otherwise answers
// with a small description of the API so `curl localhost:8080` says something
// useful.
func (s *Server) serveRoot(w http.ResponseWriter, r *http.Request) {
	if s.serveWebAsset(w, r) {
		return
	}
	if r.URL.Path != "/" {
		http.NotFound(w, r)
		return
	}
	kinds := []string{}
	for _, m := range []string{
		"ratatosk.v1.AuthService",
		"ratatosk.v1.ChatService",
		"ratatosk.v1.SocialService",
		"ratatosk.v1.KeyService",
	} {
		kinds = append(kinds, m)
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"name":      "ratatosk",
		"services":  kinds,
		"publicUrl": s.cfg.PublicURL,
		"hint":      "no web app found; build it with `flutter build web` and start with --web <dir>",
	})
}

// serveWebAsset serves one file of the built Flutter web app. It reports
// whether it handled the request.
//
// The app is a single page, so anything that is not an existing file falls back
// to index.html: a deep link like /?invite=CODE or a future client-side route
// must reach the app rather than a 404. The routes registered on the mux
// (the RPC paths, /files/, /join/, /invite/, /healthz) are more specific
// patterns, so Go's router sends them here only when they are not the target —
// which is exactly the split wanted: server-rendered pages stay server-rendered.
func (s *Server) serveWebAsset(w http.ResponseWriter, r *http.Request) bool {
	if s.cfg.WebDir == "" {
		return false
	}
	// Only GET and HEAD are served. An RPC or an upload that lands here has
	// gone astray — a client whose base url has a stray query string, say — and
	// answering it with an HTML page turns a clear "wrong url" into a confusing
	// "unsupported content type" in the client. A 404 says what happened.
	if r.Method != http.MethodGet && r.Method != http.MethodHead {
		http.NotFound(w, r)
		return true
	}
	path := path.Clean("/" + strings.TrimPrefix(r.URL.Path, "/"))
	// Refuse anything that tries to climb out of the directory. Clean already
	// removes "..", so this is belt and braces.
	if strings.Contains(path, "..") {
		http.NotFound(w, r)
		return true
	}

	candidate := filepath.Join(s.cfg.WebDir, filepath.FromSlash(strings.TrimPrefix(path, "/")))
	if info, err := os.Stat(candidate); err == nil && !info.IsDir() {
		s.serveWebFile(w, r, candidate)
		return true
	}

	index := filepath.Join(s.cfg.WebDir, "index.html")
	if _, err := os.Stat(index); err != nil {
		// A web directory without an index is not a web app; fall through to
		// the API description rather than 404ing everything.
		return false
	}
	s.serveWebFile(w, r, index)
	return true
}

func (s *Server) serveWebFile(w http.ResponseWriter, r *http.Request, file string) {
	// Everything is revalidated rather than cached on trust.
	//
	// Flutter's build does not content-address its entry points: `main.dart.js`
	// is that name in every build, so a long max-age leaves a returning visitor
	// running the previous app for as long as the header says — through a
	// redeploy, a bug fix, anything. `no-cache` does not mean "do not store": it
	// means "revalidate", and `http.ServeFile` answers with the Last-Modified
	// check, so an unchanged file costs a 304 and the 3 MB of JavaScript is
	// transferred only when it actually changed.
	w.Header().Set("Cache-Control", "no-cache")
	http.ServeFile(w, r, file)
}

func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(status)
	enc := json.NewEncoder(w)
	enc.SetIndent("", "  ")
	_ = enc.Encode(v)
}
