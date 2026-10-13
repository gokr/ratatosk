package googleid_test

import (
	"context"
	"crypto/rand"
	"crypto/rsa"
	"encoding/base64"
	"encoding/json"
	"math/big"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/golang-jwt/jwt/v5"

	"github.com/gokr/ratatosk/server/internal/googleid"
)

// The tests below exist because every failure mode here is silent: a verifier that
// accepts too much still works perfectly for honest users, and only shows up when
// somebody is dishonest.

const clientID = "53231760727-test.apps.googleusercontent.com"

type keys struct {
	key *rsa.PrivateKey
	kid string
}

// jwksServer serves the test key as Google would publish it.
func jwksServer(t *testing.T, k keys, calls *int) *httptest.Server {
	t.Helper()
	doc := map[string]any{"keys": []map[string]any{{
		"kid": k.kid, "kty": "RSA", "alg": "RS256", "use": "sig",
		"n": base64.RawURLEncoding.EncodeToString(k.key.N.Bytes()),
		"e": base64.RawURLEncoding.EncodeToString(big.NewInt(int64(k.key.E)).Bytes()),
	}}}
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if calls != nil {
			*calls++
		}
		_ = json.NewEncoder(w).Encode(doc)
	}))
	t.Cleanup(srv.Close)
	return srv
}

func signed(t *testing.T, k keys, claims jwt.MapClaims) string {
	t.Helper()
	token := jwt.NewWithClaims(jwt.SigningMethodRS256, claims)
	token.Header["kid"] = k.kid
	out, err := token.SignedString(k.key)
	if err != nil {
		t.Fatalf("sign: %v", err)
	}
	return out
}

func newKey(t *testing.T) keys {
	t.Helper()
	k, err := rsa.GenerateKey(rand.Reader, 2048)
	if err != nil {
		t.Fatalf("key: %v", err)
	}
	return keys{key: k, kid: "test-key-1"}
}

func validClaims() jwt.MapClaims {
	return jwt.MapClaims{
		"iss":            "https://accounts.google.com",
		"aud":            clientID,
		"sub":            "1138729182736455",
		"email":          "goran@example.com",
		"email_verified": true,
		"name":           "Göran Krampe",
		"iat":            time.Now().Add(-time.Minute).Unix(),
		"exp":            time.Now().Add(time.Hour).Unix(),
	}
}

// verifierFor points the verifier at the test JWKS by overriding the fetch URL,
// which is the only seam needed to test the checks without the real Google.
func verifierFor(t *testing.T, srv *httptest.Server, id string) *googleid.Verifier {
	t.Helper()
	v := googleid.New(id, srv.Client())
	googleid.SetJWKSURLForTest(v, srv.URL)
	t.Cleanup(func() { googleid.SetJWKSURLForTest(v, "") })
	return v
}

func TestValidTokenIsAccepted(t *testing.T) {
	k := newKey(t)
	srv := jwksServer(t, k, nil)
	v := verifierFor(t, srv, clientID)

	got, err := v.Verify(context.Background(), signed(t, k, validClaims()))
	if err != nil {
		t.Fatalf("verify: %v", err)
	}
	if got.Subject != "1138729182736455" {
		t.Errorf("subject = %q", got.Subject)
	}
	if !got.EmailVerified || got.Email != "goran@example.com" {
		t.Errorf("email fields = %+v", got)
	}
}

// A token minted for a different application must not sign anyone in here. Without
// this check, a token from any other site an attacker owns becomes a master key.
func TestWrongAudienceIsRejected(t *testing.T) {
	k := newKey(t)
	srv := jwksServer(t, k, nil)
	v := verifierFor(t, srv, clientID)

	claims := validClaims()
	claims["aud"] = "9999-someone-elses-app.apps.googleusercontent.com"
	if _, err := v.Verify(context.Background(), signed(t, k, claims)); err == nil {
		t.Fatal("a token for another application was accepted")
	}
	// A list containing our id is accepted; one that does not contain it is not.
	claims["aud"] = []any{"other", clientID}
	if _, err := v.Verify(context.Background(), signed(t, k, claims)); err != nil {
		t.Errorf("a list audience containing our id was rejected: %v", err)
	}
	claims["aud"] = []any{"other"}
	if _, err := v.Verify(context.Background(), signed(t, k, claims)); err == nil {
		t.Error("a list audience without our id was accepted")
	}
}

func TestExpiredAndForeignIssuerAreRejected(t *testing.T) {
	k := newKey(t)
	srv := jwksServer(t, k, nil)
	v := verifierFor(t, srv, clientID)

	expired := validClaims()
	expired["exp"] = time.Now().Add(-time.Minute).Unix()
	if _, err := v.Verify(context.Background(), signed(t, k, expired)); err == nil {
		t.Error("an expired token was accepted")
	}
	foreign := validClaims()
	foreign["iss"] = "https://accounts.evil.example"
	if _, err := v.Verify(context.Background(), signed(t, k, foreign)); err == nil {
		t.Error("a token from another issuer was accepted")
	}
	noSubject := validClaims()
	delete(noSubject, "sub")
	if _, err := v.Verify(context.Background(), signed(t, k, noSubject)); err == nil {
		t.Error("a token without a subject was accepted")
	}
}

// A token signed by a key Google never published must be refused, which is what
// stops anyone from minting one.
func TestForeignSignatureIsRejected(t *testing.T) {
	trusted, attacker := newKey(t), newKey(t)
	srv := jwksServer(t, trusted, nil)
	v := verifierFor(t, srv, clientID)

	token := jwt.NewWithClaims(jwt.SigningMethodRS256, validClaims())
	token.Header["kid"] = trusted.kid // claims a key it was not signed with
	signedByAttacker, err := token.SignedString(attacker.key)
	if err != nil {
		t.Fatalf("sign: %v", err)
	}
	if _, err := v.Verify(context.Background(), signedByAttacker); err == nil {
		t.Fatal("a token signed with an unpublished key was accepted")
	}
}

// The classic JWT forgery: swap the algorithm for `none` and drop the signature.
func TestUnsignedTokenIsRejected(t *testing.T) {
	k := newKey(t)
	srv := jwksServer(t, k, nil)
	v := verifierFor(t, srv, clientID)

	token := jwt.NewWithClaims(jwt.SigningMethodNone, validClaims())
	unsigned, err := token.SignedString(jwt.UnsafeAllowNoneSignatureType)
	if err != nil {
		t.Fatalf("sign none: %v", err)
	}
	if _, err := v.Verify(context.Background(), unsigned); err == nil {
		t.Fatal("an unsigned token was accepted")
	}
}

func TestGarbageIsRejected(t *testing.T) {
	k := newKey(t)
	srv := jwksServer(t, k, nil)
	v := verifierFor(t, srv, clientID)

	for _, token := range []string{"", "not-a-token", "a.b.c", strings.Repeat("x", 100)} {
		if _, err := v.Verify(context.Background(), token); err == nil {
			t.Errorf("%q was accepted", token)
		}
	}
}

// An unconfigured server must refuse rather than treat every caller as anonymous.
func TestUnconfiguredVerifierIsUnavailable(t *testing.T) {
	v := googleid.New("", nil)
	if v.Available() {
		t.Fatal("an empty client id reported itself available")
	}
	if _, err := v.Verify(context.Background(), "anything"); err == nil {
		t.Fatal("an unconfigured verifier accepted a token")
	}
}

// Keys are cached: a JWKS fetch per login would make Google an availability
// dependency of signing in, and would hammer it.
func TestKeysAreCachedAcrossVerifications(t *testing.T) {
	k := newKey(t)
	calls := 0
	srv := jwksServer(t, k, &calls)
	v := verifierFor(t, srv, clientID)

	for i := 0; i < 3; i++ {
		if _, err := v.Verify(context.Background(), signed(t, k, validClaims())); err != nil {
			t.Fatalf("verify %d: %v", i, err)
		}
	}
	if calls != 1 {
		t.Errorf("fetched Google's keys %d times for 3 logins, want 1", calls)
	}
}
