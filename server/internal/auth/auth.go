// Package auth handles password hashing and the request identity that the
// interceptor attaches to the context.
package auth

import (
	"context"
	"crypto/pbkdf2"
	"crypto/rand"
	"crypto/sha256"
	"crypto/subtle"
	"encoding/hex"
	"errors"
	"fmt"
	"regexp"
	"strings"

	"github.com/gokr/ratatosk/server/internal/store"
)

// Password hashing parameters. 120k PBKDF2-SHA256 iterations is the OWASP
// recommendation for this construction and costs a few milliseconds per login,
// which is the point.
const (
	pbkdf2Iterations = 120_000
	pbkdf2KeyLen     = 32
	saltLen          = 16
)

// usernamePattern keeps handles URL-, mention- and typo-friendly: no casing
// games, no spaces, no leading punctuation.
var usernamePattern = regexp.MustCompile(`^[a-z][a-z0-9._-]{2,31}$`)

// ValidateUsername reports why a handle is unacceptable, if it is.
func ValidateUsername(username string) error {
	if !usernamePattern.MatchString(username) {
		return errors.New("username must be 3-32 characters: lowercase letters, digits, dot, underscore or hyphen, starting with a letter")
	}
	return nil
}

// ValidatePassword enforces a floor that is low enough to be practical and
// high enough to matter. Length beats composition rules.
func ValidatePassword(password string) error {
	if len(password) < 8 {
		return errors.New("password must be at least 8 characters")
	}
	if len(password) > 256 {
		return errors.New("password must be at most 256 characters")
	}
	return nil
}

// HashPassword returns the hex-encoded hash and salt to store.
func HashPassword(password string) (hash, salt string, err error) {
	raw := make([]byte, saltLen)
	if _, err := rand.Read(raw); err != nil {
		return "", "", fmt.Errorf("auth: salt: %w", err)
	}
	key, err := pbkdf2.Key(sha256.New, password, raw, pbkdf2Iterations, pbkdf2KeyLen)
	if err != nil {
		return "", "", fmt.Errorf("auth: hash: %w", err)
	}
	return hex.EncodeToString(key), hex.EncodeToString(raw), nil
}

// VerifyPassword compares a candidate password against a stored hash in
// constant time.
func VerifyPassword(password, hash, salt string) bool {
	saltRaw, err := hex.DecodeString(salt)
	if err != nil {
		return false
	}
	want, err := hex.DecodeString(hash)
	if err != nil {
		return false
	}
	got, err := pbkdf2.Key(sha256.New, password, saltRaw, pbkdf2Iterations, len(want))
	if err != nil {
		return false
	}
	return subtle.ConstantTimeCompare(got, want) == 1
}

// NormalizeUsername lowercases and trims a handle as typed by a human.
func NormalizeUsername(username string) string {
	return strings.ToLower(strings.TrimSpace(username))
}

type ctxKey int

const (
	userKey ctxKey = iota
	tokenKey
	deviceKeyID
)

// WithIdentity attaches the authenticated user and the token that proved it.
func WithIdentity(ctx context.Context, u *store.User, token string) context.Context {
	ctx = context.WithValue(ctx, userKey, u)
	return context.WithValue(ctx, tokenKey, token)
}

// WithDeviceKey attaches the device key the caller says it is using. The
// interceptor has already checked that the key belongs to the user; services
// use it to address this device's own key envelopes.
func WithDeviceKey(ctx context.Context, id string) context.Context {
	return context.WithValue(ctx, deviceKeyID, id)
}

// DeviceKeyFrom returns the caller's device key id, or "" when the client did
// not name one.
func DeviceKeyFrom(ctx context.Context) string {
	id, _ := ctx.Value(deviceKeyID).(string)
	return id
}

// UserFrom returns the authenticated user, if any.
func UserFrom(ctx context.Context) (*store.User, bool) {
	u, ok := ctx.Value(userKey).(*store.User)
	return u, ok && u != nil
}

// TokenFrom returns the bearer token of the current call.
func TokenFrom(ctx context.Context) string {
	t, _ := ctx.Value(tokenKey).(string)
	return t
}
