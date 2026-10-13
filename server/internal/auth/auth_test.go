package auth_test

import (
	"testing"

	"github.com/gokr/ratatosk/server/internal/auth"
)

// An account created through a social login has no password. `VerifyPassword` of
// an empty hash must never succeed: `pbkdf2` asked for zero bytes returns an empty
// key, and comparing two empty slices is a match, so without a guard the account
// would open with any password typed at the login form.
func TestEmptyCredentialNeverVerifies(t *testing.T) {
	for _, password := range []string{"", "anything", "correct horse battery"} {
		if auth.VerifyPassword(password, "", "") {
			t.Errorf("an account with no password accepted %q", password)
		}
	}
	// A stored password still verifies, and the wrong one still fails, so the guard
	// did not break the normal path.
	hash, salt, err := auth.HashPassword("correct horse battery")
	if err != nil {
		t.Fatalf("hash: %v", err)
	}
	if !auth.VerifyPassword("correct horse battery", hash, salt) {
		t.Error("a real password stopped verifying")
	}
	if auth.VerifyPassword("wrong", hash, salt) {
		t.Error("the wrong password verified")
	}
	// Degenerate halves must fail too, not just both-empty.
	if auth.VerifyPassword("x", "", salt) || auth.VerifyPassword("x", hash, "") {
		t.Error("a half-empty credential verified")
	}
}
