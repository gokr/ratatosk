// Package googleid verifies Google's OpenID Connect ID tokens.
//
// The rules here are the whole security of "Sign in with Google":
//
//   - The token's signature is checked against Google's published keys, fetched
//     from its JWKS document and cached. Verify with the network in the path and a
//     slow JWKS fetch becomes a login outage; verify nothing and anyone can mint a
//     token.
//   - The audience must be our client id. Without that check, a token minted for
//     any other application — including one an attacker controls — would be
//     accepted here.
//   - The issuer must be Google, and the expiry is enforced.
//   - The identity is the `sub` claim, never the email. An email can be reassigned
//     on Google's side; a subject cannot. Trusting the address is how social login
//     becomes account takeover.
//
// This is written against the standard library plus golang-jwt rather than an
// OIDC package: the checks above are the entire requirement, and every one of
// them is explicit here.
package googleid

import (
	"context"
	"crypto"
	"crypto/rsa"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"math/big"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

// Issuers Google may use. Both spellings appear in real tokens; accepting only
// one rejects valid logins for no benefit.
var issuers = map[string]bool{
	"https://accounts.google.com": true,
	"accounts.google.com":         true,
}

// Identity is what a verified token says about its holder. Deliberately fewer
// fields than the token contains: nothing outside this struct is allowed to
// influence an account.
type Identity struct {
	// Subject is the immutable Google user id. This is the identity.
	Subject string
	Email   string
	// EmailVerified is Google's assertion that it controls the address. It gates
	// informational use only — never account matching.
	EmailVerified bool
	Name          string
}

type verifier struct {
	clientID string
	client   *http.Client
	// jwksURL is a seam for tests; empty means Google's real endpoint.
	jwksURL string

	mu      sync.Mutex
	keys    map[string]*rsa.PublicKey
	fetched time.Time
}

// Verifier checks ID tokens for one client id.
type Verifier struct {
	inner *verifier
}

// New returns a verifier for a Google client id. An empty client id means the
// operator has not configured Google sign-in, and the returned verifier reports
// itself unavailable rather than accepting anything.
func New(clientID string, client *http.Client) *Verifier {
	if client == nil {
		client = &http.Client{Timeout: 10 * time.Second}
	}
	return &Verifier{inner: &verifier{clientID: strings.TrimSpace(clientID), client: client}}
}

// NewWithJWKSURL builds a verifier that reads the key set from somewhere other
// than Google: a self-hosted mirror, a proxy, or a test. It is a configuration seam
// rather than a test hook, because a deployment behind a restrictive network needs
// exactly this to verify tokens at all.
func NewWithJWKSURL(clientID, jwksURL string, client *http.Client) *Verifier {
	v := New(clientID, client)
	if jwksURL != "" {
		SetJWKSURLForTest(v, jwksURL)
	}
	return v
}

// Available reports whether Google sign-in is configured at all.
func (v *Verifier) Available() bool { return v != nil && v.inner != nil && v.inner.clientID != "" }

var (
	ErrUnavailable = errors.New("google sign-in is not configured on this server")
	ErrInvalid     = errors.New("that sign-in token is not valid")
)

// SetJWKSURLForTest points a verifier at another key set. An empty url restores
// Google's. It exists so the verification rules can be tested without the network,
// which is the only way to test the rejections — a real Google will not mint a
// token with the wrong audience for us.
func SetJWKSURLForTest(v *Verifier, url string) {
	if v == nil || v.inner == nil {
		return
	}
	v.inner.mu.Lock()
	defer v.inner.mu.Unlock()
	v.inner.jwksURL = url
	v.inner.keys = nil
	v.inner.fetched = time.Time{}
}

// Verify checks a token and returns the identity it proves.
func (v *Verifier) Verify(ctx context.Context, token string) (*Identity, error) {
	if !v.Available() {
		return nil, ErrUnavailable
	}
	token = strings.TrimSpace(token)
	if token == "" {
		return nil, ErrInvalid
	}

	claims := jwt.MapClaims{}
	parsed, err := jwt.ParseWithClaims(token, claims, func(t *jwt.Token) (any, error) {
		if _, ok := t.Method.(*jwt.SigningMethodRSA); !ok {
			// Anything that is not an RS256-family signature is refused outright:
			// accepting the token's own `alg` is the classic JWT forgery.
			return nil, fmt.Errorf("unexpected signing method %v", t.Header["alg"])
		}
		kid, _ := t.Header["kid"].(string)
		return v.inner.key(ctx, kid)
	}, jwt.WithExpirationRequired(), jwt.WithIssuedAt(), jwt.WithValidMethods([]string{"RS256", "RS384", "RS512"}))
	if err != nil || !parsed.Valid {
		return nil, ErrInvalid
	}

	if iss, _ := claims["iss"].(string); !issuers[iss] {
		return nil, ErrInvalid
	}
	// The audience may be a string or a list; both forms occur in the wild.
	if !audienceMatches(claims["aud"], v.inner.clientID) {
		return nil, ErrInvalid
	}
	subject, _ := claims["sub"].(string)
	if subject == "" {
		return nil, ErrInvalid
	}
	// An address Google has not verified must never be treated as belonging to
	// anyone; the caller uses this to decide what it may show, not to match
	// accounts.
	email, _ := claims["email"].(string)
	verified, _ := claims["email_verified"].(bool)
	name, _ := claims["name"].(string)
	return &Identity{
		Subject:       subject,
		Email:         email,
		EmailVerified: verified,
		Name:          strings.TrimSpace(name),
	}, nil
}

func audienceMatches(aud any, clientID string) bool {
	switch v := aud.(type) {
	case string:
		return v == clientID
	case []any:
		for _, item := range v {
			if s, ok := item.(string); ok && s == clientID {
				return true
			}
		}
	}
	return false
}

// key returns the public key for a token's `kid`, fetching Google's JWKS when the
// key is unknown or the cache has aged out.
func (v *verifier) key(ctx context.Context, kid string) (*rsa.PublicKey, error) {
	v.mu.Lock()
	cached, ok := v.keys[kid]
	fresh := time.Since(v.fetched) < time.Hour
	v.mu.Unlock()
	if ok && fresh {
		return cached, nil
	}

	keys, err := v.fetch(ctx)
	if err != nil {
		// A stale cache beats a failed login: Google's keys rotate on the order of
		// weeks, so an hour-old set is still almost certainly right, and refusing
		// every sign-in because JWKS is briefly unreachable trades a real outage
		// for a theoretical one.
		if ok {
			return cached, nil
		}
		return nil, err
	}
	v.mu.Lock()
	v.keys = keys
	v.fetched = time.Now()
	v.mu.Unlock()
	if k, ok := keys[kid]; ok {
		return k, nil
	}
	if kid == "" && len(keys) == 1 {
		for _, only := range keys {
			return only, nil
		}
	}
	return nil, fmt.Errorf("no key %q in Google's published set", kid)
}

type jwksDocument struct {
	Keys []struct {
		Kid string `json:"kid"`
		Kty string `json:"kty"`
		Alg string `json:"alg"`
		Use string `json:"use"`
		N   string `json:"n"`
		E   string `json:"e"`
	} `json:"keys"`
}

func (v *verifier) fetch(ctx context.Context) (map[string]*rsa.PublicKey, error) {
	url := v.jwksURL
	if url == "" {
		url = "https://www.googleapis.com/oauth2/v3/certs"
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return nil, err
	}
	resp, err := v.client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("fetch google keys: %w", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("fetch google keys: status %d", resp.StatusCode)
	}
	var doc jwksDocument
	if err := json.NewDecoder(resp.Body).Decode(&doc); err != nil {
		return nil, fmt.Errorf("decode google keys: %w", err)
	}
	out := make(map[string]*rsa.PublicKey, len(doc.Keys))
	for _, k := range doc.Keys {
		if k.Kty != "RSA" || k.N == "" || k.E == "" {
			continue
		}
		modulus, err := base64.RawURLEncoding.DecodeString(k.N)
		if err != nil {
			continue
		}
		exponent, err := base64.RawURLEncoding.DecodeString(k.E)
		if err != nil {
			continue
		}
		out[k.Kid] = &rsa.PublicKey{
			N: new(big.Int).SetBytes(modulus),
			E: int(new(big.Int).SetBytes(exponent).Int64()),
		}
	}
	if len(out) == 0 {
		return nil, errors.New("google published no usable keys")
	}
	return out, nil
}

// Ensure the standard library's hashes are linked, since golang-jwt needs them
// for RSA verification and does not import them itself.
var _ = crypto.SHA256
var _ = sha256.New
