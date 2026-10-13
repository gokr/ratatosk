package httpserver

import (
	"context"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"net/url"
	"strings"
	"time"

	"github.com/gokr/ratatosk/server/internal/googleid"
	"github.com/gokr/ratatosk/server/internal/ids"
	"github.com/gokr/ratatosk/server/internal/service"
	"github.com/gokr/ratatosk/server/internal/store"
)

// Google sign-in, server side.
//
// The flow is the authorization-code kind with PKCE, not the implicit one, and that
// choice is what makes the client secret optional rather than decorative:
//
//  1. The browser is sent to Google with a state and a code challenge.
//  2. Google sends it back to /auth/google/callback with a code.
//  3. The server exchanges the code for tokens, proving it started the flow with
//     the PKCE verifier it kept (step 1) — the verifier never leaves the server.
//  4. The identity is verified, and the outcome depends on whether it is already
//     linked: a session, or a pending registration the app completes with a
//     username and an invitation.
//
// Nothing in this file trusts the browser with a claim: the state is opaque and
// single-use, the verifier stays server-side, and the identity is remembered
// server-side between the two steps.

const googleAuthEndpoint = "https://accounts.google.com/o/oauth2/v2/auth"
const googleTokenEndpoint = "https://oauth2.googleapis.com/token"

// oauthStateLifetime is how long a started sign-in may take. Generous enough for
// someone to pick an account and consent, short enough to forget an abandoned one.
const oauthStateLifetime = 10 * time.Minute

// oauthTicketPurposeLink marks a ticket as belonging to the linking flow, so one
// obtained for another purpose cannot be spent here.
const oauthTicketPurposeLink = "google-link"

// oauthTicketLifetime is how long the app has to send the browser to the link
// endpoint after asking for the URL. Short: it is spent immediately, and a ticket in
// a URL is the one thing worth keeping brief.
const oauthTicketLifetime = 5 * time.Minute

// serveGoogleLinkStart begins *linking* Google to the account that started it.
//
// Separate from the sign-in start because the two must not be interchangeable: a
// linking attempt carries the account it belongs to, and its callback attaches the
// identity there instead of issuing a session. Without that distinction, a linking
// URL would be a way to sign in as somebody else, or a sign-in URL a way to attach
// an identity to whoever started it.
//
// Requires a bearer token: this is only ever started by a signed-in person.
func (s *Server) serveGoogleLinkStart(w http.ResponseWriter, r *http.Request) {
	if !s.google.Available() {
		s.googleFail(r, w, "Google sign-in is not configured on this server.")
		return
	}
	// A ticket, not a bearer token: this endpoint is reached by the browser
	// *navigating* here, and a navigation carries no Authorization header. The app
	// obtained the ticket over an authenticated RPC moments ago.
	ticket, err := s.st.TakeOAuthTicket(r.URL.Query().Get("t"), oauthTicketPurposeLink, time.Now())
	if err != nil {
		s.googleLinkFail(r, w, "That request expired. Try connecting Google again.")
		return
	}
	state, err := s.beginGoogle(r, ticket.UserID)
	if err != nil {
		s.log.Error("could not store oauth link state", "err", err)
		s.googleLinkFail(r, w, "Could not start connecting Google. Try again.")
		return
	}
	http.Redirect(w, r, s.googleConsentURL(state), http.StatusFound)
}

func (s *Server) serveGoogleStart(w http.ResponseWriter, r *http.Request) {
	if !s.google.Available() {
		s.googleFail(r, w, "Google sign-in is not configured on this server.")
		return
	}
	state, err := s.beginGoogle(r, "")
	if err != nil {
		s.log.Error("could not store oauth state", "err", err)
		s.googleFail(r, w, "Could not start sign-in. Try again.")
		return
	}
	http.Redirect(w, r, s.googleConsentURL(state), http.StatusFound)
}

// beginGoogle stores a pending attempt and returns its opaque state.
//
// `linkUserID` is empty for signing in and set for linking; it is the single field
// that decides what the callback does, which is why it is recorded here rather than
// passed through the browser.
func (s *Server) beginGoogle(r *http.Request, linkUserID string) (string, error) {
	// PKCE: the verifier stays here, the challenge goes to Google. Without this a
	// code intercepted in transit could be exchanged by somebody else.
	verifier := ids.Token() + ids.Token()
	state := ids.Token()
	now := time.Now()
	if err := s.st.PutOAuthState(&store.OAuthState{
		State:        state,
		CodeVerifier: verifier,
		RedirectURI:  s.googleRedirectURI(),
		UserID:       linkUserID,
		CreatedAt:    now,
		ExpiresAt:    now.Add(oauthStateLifetime),
	}); err != nil {
		return "", err
	}
	return state, nil
}

// googleConsentURL is where the browser is sent to ask Google.
func (s *Server) googleConsentURL(state string) string {
	// The challenge is recomputed from the stored verifier so the two can never
	// disagree; a mismatch would fail at the token endpoint with a message that
	// blames the client.
	stored, err := s.st.OAuthStateByState(state)
	challenge := ""
	if err == nil {
		sum := sha256.Sum256([]byte(stored.CodeVerifier))
		challenge = base64.RawURLEncoding.EncodeToString(sum[:])
	}

	q := url.Values{}
	q.Set("client_id", s.cfg.GoogleClientID)
	q.Set("redirect_uri", s.googleRedirectURI())
	q.Set("response_type", "code")
	// The two scopes the published policy names, and no others: adding more means
	// asking users for more than the policy says we take.
	q.Set("scope", "openid email profile")
	q.Set("state", state)
	q.Set("code_challenge", challenge)
	q.Set("code_challenge_method", "S256")
	// offline access is not requested: there is nothing to do on the user's behalf
	// later, so asking for a refresh token would be collecting a capability we do
	// not need.
	q.Set("prompt", "select_account")
	return s.googleAuthURL() + "?" + q.Encode()
}

func (s *Server) serveGoogleCallback(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	if err := q.Get("error"); err != "" {
		// The person pressed "cancel", or Google refused. Not an error worth a log
		// line as a failure.
		s.googleFail(r, w, "Sign-in was cancelled.")
		return
	}
	if !s.google.Available() {
		s.googleFail(r, w, "Google sign-in is not configured on this server.")
		return
	}
	state, err := s.st.TakeOAuthState(q.Get("state"), time.Now())
	if err != nil {
		// Unknown, already used, or expired. All of them mean "start again": the
		// distinction does not help the person and would leak whether a state ever
		// existed.
		s.googleFail(r, w, "That sign-in took too long or was already used. Try again.")
		return
	}
	code := q.Get("code")
	if code == "" {
		s.googleFail(r, w, "Google did not return a sign-in code.")
		return
	}

	id, err := s.exchangeGoogleCode(r.Context(), code, state.CodeVerifier, state.RedirectURI)
	if err != nil {
		s.log.Error("google code exchange failed", "err", err)
		s.googleFail(r, w, "Could not complete sign-in with Google.")
		return
	}

	if state.UserID != "" {
		// A linking attempt: attach the identity to the account that started it.
		// No session is issued and no new account can appear.
		if err := s.services.Auth.LinkGoogleIdentity(r.Context(), state.UserID, id); err != nil {
			s.log.Info("google link refused", "user", state.UserID, "err", err)
			s.googleLinkFail(r, w, err.Error())
			return
		}
		s.googleLinkDone(r, w)
		return
	}

	result, err := s.services.Auth.StartGoogleSignIn(r.Context(), id)
	if err != nil {
		s.log.Error("google sign-in could not be resolved", "err", err)
		s.googleFail(r, w, "Could not complete sign-in.")
		return
	}
	s.finishGoogle(r, w, result)
}

// googleLinkDone sends the browser back to the app with a plain success.
func (s *Server) googleLinkDone(r *http.Request, w http.ResponseWriter) {
	target, err := url.Parse(s.cfg.PublicURL)
	if err != nil {
		http.Error(w, "ok", http.StatusOK)
		return
	}
	q := target.Query()
	q.Set("google_linked", "1")
	target.RawQuery = q.Encode()
	w.Header().Set("Cache-Control", "no-store")
	http.Redirect(w, r, target.String(), http.StatusFound)
}

// googleLinkFail reports why connecting Google was refused, in the app's own words.
//
// The message is one this server chose, never anything a request supplied, and it is
// passed to the app so the person sees it on the screen they started from.
func (s *Server) googleLinkFail(r *http.Request, w http.ResponseWriter, message string) {
	target, err := url.Parse(s.cfg.PublicURL)
	if err != nil {
		http.Error(w, message, http.StatusBadRequest)
		return
	}
	q := target.Query()
	q.Set("google_link_error", message)
	target.RawQuery = q.Encode()
	w.Header().Set("Cache-Control", "no-store")
	http.Redirect(w, r, target.String(), http.StatusFound)
}

// exchangeGoogleCode trades the authorization code for the identity it proves.
func (s *Server) exchangeGoogleCode(ctx context.Context, code, verifier, redirectURI string) (*googleid.Identity, error) {
	form := url.Values{}
	form.Set("code", code)
	form.Set("client_id", s.cfg.GoogleClientID)
	form.Set("redirect_uri", redirectURI)
	form.Set("grant_type", "authorization_code")
	form.Set("code_verifier", verifier)
	// The secret is included when configured — Google's web clients are "confidential"
	// and require it — but the flow does not *depend* on it, because PKCE is what
	// actually binds the exchange to this server.
	if s.cfg.GoogleClientSecret != "" {
		form.Set("client_secret", s.cfg.GoogleClientSecret)
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, s.googleTokenURL(),
		strings.NewReader(form.Encode()))
	if err != nil {
		return nil, err
	}
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	resp, err := s.httpClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	var body struct {
		IDToken string `json:"id_token"`
		Error   string `json:"error"`
		Detail  string `json:"error_description"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&body); err != nil {
		return nil, fmt.Errorf("decode token response: %w", err)
	}
	if resp.StatusCode != http.StatusOK || body.Error != "" {
		return nil, fmt.Errorf("token endpoint: %s %s (status %d)", body.Error, body.Detail, resp.StatusCode)
	}
	if body.IDToken == "" {
		return nil, errors.New("token endpoint returned no id_token")
	}
	return s.google.Verify(ctx, body.IDToken)
}

// finishGoogle hands the browser back to the app with either a session or a pending
// registration.
//
// The hand-back is a redirect to the app's own origin with the result in the query
// string. The app is the only client that reaches this, and a pending token is
// single-use and short-lived, so putting it in the URL is a smaller exposure than an
// extra round trip through a page the server would have to render.
func (s *Server) finishGoogle(r *http.Request, w http.ResponseWriter, result *service.OAuthSignInResult) {
	target, err := url.Parse(s.cfg.PublicURL)
	if err != nil {
		s.googleFail(r, w, "Server misconfiguration.")
		return
	}
	q := target.Query()
	if result.PendingToken != "" {
		q.Set("google_pending", result.PendingToken)
		if result.SuggestName != "" {
			q.Set("google_suggested_username", result.SuggestName)
		}
		if result.Email != "" {
			q.Set("google_email", result.Email)
		}
	} else {
		q.Set("google_token", result.Token)
	}
	target.RawQuery = q.Encode()
	w.Header().Set("Cache-Control", "no-store")
	http.Redirect(w, r, target.String(), http.StatusFound)
}

// googleFail sends the browser back to the app with a message it can show.
//
// Back to the app rather than a bare error page: the person is in the middle of
// signing in, and stranding them on a blank page loses the context for what to do
// next. The message is a fixed string chosen here, never anything a request supplied.
func (s *Server) googleFail(r *http.Request, w http.ResponseWriter, message string) {
	target, err := url.Parse(s.cfg.PublicURL)
	if err != nil {
		http.Error(w, message, http.StatusBadRequest)
		return
	}
	q := target.Query()
	q.Set("google_error", message)
	target.RawQuery = q.Encode()
	w.Header().Set("Cache-Control", "no-store")
	http.Redirect(w, r, target.String(), http.StatusFound)
}

// googleTokenURL and googleAuthURL are the two endpoints of the flow, overridable
// for a proxy or a test.
func (s *Server) googleTokenURL() string {
	if s.cfg.GoogleTokenURL != "" {
		return s.cfg.GoogleTokenURL
	}
	return googleTokenEndpoint
}

func (s *Server) googleAuthURL() string {
	if s.cfg.GoogleAuthURL != "" {
		return s.cfg.GoogleAuthURL
	}
	return googleAuthEndpoint
}

func (s *Server) googleRedirectURI() string {
	base := strings.TrimRight(s.cfg.PublicURL, "/")
	return base + "/auth/google/callback"
}
