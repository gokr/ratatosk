package service

import (
	"context"

	"connectrpc.com/connect"

	"github.com/gokr/ratatosk/server/internal/auth"
	"github.com/gokr/ratatosk/server/internal/store"
)

// userOrNil returns the authenticated caller when there is one. Used by the
// few calls that work anonymously but behave differently when signed in.
func userOrNil(ctx context.Context) (*store.User, bool) {
	return auth.UserFrom(ctx)
}

// requireMember loads a conversation and checks that the caller is in it, for
// services that own no conversation logic of their own.
func (b *base) requireMember(ctx context.Context, convID string) (*store.User, *store.Conversation, error) {
	user, err := b.requireUser(ctx)
	if err != nil {
		return nil, nil, err
	}
	c, err := b.st.ConversationByID(convID)
	if err != nil {
		return nil, nil, connect.NewError(connect.CodeNotFound, errInvalid("conversation not found"))
	}
	if _, ok := c.Members[user.ID]; !ok {
		return nil, nil, connect.NewError(connect.CodePermissionDenied, errInvalid("you are not in this conversation"))
	}
	return user, c, nil
}
