package service

import (
	"context"

	"github.com/gokr/ratatosk/server/internal/auth"
	"github.com/gokr/ratatosk/server/internal/store"
)

// userOrNil returns the authenticated caller when there is one. Used by the
// few calls that work anonymously but behave differently when signed in.
func userOrNil(ctx context.Context) (*store.User, bool) {
	return auth.UserFrom(ctx)
}
