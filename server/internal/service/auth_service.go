package service

import (
	"context"

	"connectrpc.com/connect"

	ratatoskv1 "github.com/gokr/ratatosk/server/gen/ratatosk/v1"
	"github.com/gokr/ratatosk/server/internal/auth"
	"github.com/gokr/ratatosk/server/internal/store"
)

// AuthService implements ratatosk.v1.AuthService.
type AuthService struct {
	*base
}

// NewAuthService wires the auth service onto the shared state.
func NewAuthService(b *base) *AuthService { return &AuthService{base: b} }

// requireUser returns the authenticated caller or an UNAUTHENTICATED error.
func (b *base) requireUser(ctx context.Context) (*store.User, error) {
	u, ok := auth.UserFrom(ctx)
	if !ok {
		return nil, connect.NewError(connect.CodeUnauthenticated, errInvalid("sign in to continue"))
	}
	return u, nil
}

func (s *AuthService) Register(ctx context.Context, req *connect.Request[ratatoskv1.RegisterRequest]) (*connect.Response[ratatoskv1.RegisterResponse], error) {
	username := auth.NormalizeUsername(req.Msg.GetUsername())
	if err := auth.ValidateUsername(username); err != nil {
		return nil, connect.NewError(connect.CodeInvalidArgument, err)
	}
	if err := auth.ValidatePassword(req.Msg.GetPassword()); err != nil {
		return nil, connect.NewError(connect.CodeInvalidArgument, err)
	}

	displayName := trimSpace(req.Msg.GetDisplayName())
	if displayName == "" {
		displayName = username
	}
	if len(displayName) > 64 {
		return nil, connect.NewError(connect.CodeInvalidArgument, errInvalid("display name must be at most 64 characters"))
	}

	hash, salt, err := auth.HashPassword(req.Msg.GetPassword())
	if err != nil {
		s.log.Error("password hashing failed", "err", err)
		return nil, connect.NewError(connect.CodeInternal, errInvalid("could not create the account"))
	}
	now := now()
	user, err := s.st.CreateUser(username, displayName, hash, salt, s.accentFor(username), now)
	if err == store.ErrUsernameTaken {
		return nil, connect.NewError(connect.CodeAlreadyExists, errInvalid("that username is taken"))
	}
	if err != nil {
		return nil, connect.NewError(connect.CodeInternal, err)
	}
	session, err := s.st.CreateSession(user.ID, s.cfg.SessionTTL, now)
	if err != nil {
		return nil, connect.NewError(connect.CodeInternal, err)
	}
	s.log.Info("user registered", "user", user.ID, "username", user.Username)
	return connect.NewResponse(&ratatoskv1.RegisterResponse{
		Token:     session.Token,
		User:      s.userProto(user),
		ExpiresAt: ts(session.ExpiresAt),
	}), nil
}

func (s *AuthService) Login(ctx context.Context, req *connect.Request[ratatoskv1.LoginRequest]) (*connect.Response[ratatoskv1.LoginResponse], error) {
	username := auth.NormalizeUsername(req.Msg.GetUsername())
	// One error for both "no such user" and "wrong password": telling them
	// apart would turn this endpoint into a handle oracle.
	denied := connect.NewError(connect.CodeUnauthenticated, errInvalid("wrong username or password"))

	user, err := s.st.UserByUsername(username)
	if err != nil {
		return nil, denied
	}
	if !auth.VerifyPassword(req.Msg.GetPassword(), user.PasswordHash, user.PasswordSalt) {
		return nil, denied
	}
	session, err := s.st.CreateSession(user.ID, s.cfg.SessionTTL, now())
	if err != nil {
		return nil, connect.NewError(connect.CodeInternal, err)
	}
	return connect.NewResponse(&ratatoskv1.LoginResponse{
		Token:     session.Token,
		User:      s.userProto(user),
		ExpiresAt: ts(session.ExpiresAt),
	}), nil
}

func (s *AuthService) Logout(ctx context.Context, req *connect.Request[ratatoskv1.LogoutRequest]) (*connect.Response[ratatoskv1.LogoutResponse], error) {
	if token := auth.TokenFrom(ctx); token != "" {
		s.st.DeleteSession(token)
	}
	// Logout is idempotent and never fails: a client with a dead token must be
	// able to clear it.
	return connect.NewResponse(&ratatoskv1.LogoutResponse{}), nil
}

func (s *AuthService) GetMe(ctx context.Context, req *connect.Request[ratatoskv1.GetMeRequest]) (*connect.Response[ratatoskv1.GetMeResponse], error) {
	user, err := s.requireUser(ctx)
	if err != nil {
		return nil, err
	}
	// Re-read: the token's copy was taken when it was issued.
	fresh, err := s.st.UserByID(user.ID)
	if err != nil {
		return nil, connect.NewError(connect.CodeUnauthenticated, errInvalid("this account no longer exists"))
	}
	return connect.NewResponse(&ratatoskv1.GetMeResponse{User: s.userProto(fresh)}), nil
}

func (s *AuthService) UpdateProfile(ctx context.Context, req *connect.Request[ratatoskv1.UpdateProfileRequest]) (*connect.Response[ratatoskv1.UpdateProfileResponse], error) {
	user, err := s.requireUser(ctx)
	if err != nil {
		return nil, err
	}
	msg := req.Msg

	displayName := trimSpace(msg.GetDisplayName())
	if len(displayName) > 64 {
		return nil, connect.NewError(connect.CodeInvalidArgument, errInvalid("display name must be at most 64 characters"))
	}
	if len(msg.GetBio()) > 500 {
		return nil, connect.NewError(connect.CodeInvalidArgument, errInvalid("bio must be at most 500 characters"))
	}
	accent := trimSpace(msg.GetAccentColor())
	if accent != "" && !validHexColor(accent) {
		return nil, connect.NewError(connect.CodeInvalidArgument, errInvalid("accent color must look like #0084ff"))
	}
	if id := msg.GetAvatarAttachmentId(); id != "" {
		if _, err := s.st.AttachmentByID(id); err != nil {
			return nil, connect.NewError(connect.CodeInvalidArgument, errInvalid("unknown attachment"))
		}
	}

	updated, err := s.st.UpdateUser(user.ID, func(u *store.User) {
		if displayName != "" {
			u.DisplayName = displayName
		}
		if msg.Bio != nil {
			u.Bio = msg.GetBio()
		}
		if accent != "" {
			u.AccentColor = accent
		}
		if id := msg.GetAvatarAttachmentId(); id != "" {
			u.Avatar = id
		}
		if msg.GetClearAvatar() {
			u.Avatar = ""
		}
	})
	if err != nil {
		return nil, connect.NewError(connect.CodeInternal, err)
	}
	return connect.NewResponse(&ratatoskv1.UpdateProfileResponse{User: s.userProto(updated)}), nil
}

func (s *AuthService) ChangePassword(ctx context.Context, req *connect.Request[ratatoskv1.ChangePasswordRequest]) (*connect.Response[ratatoskv1.ChangePasswordResponse], error) {
	user, err := s.requireUser(ctx)
	if err != nil {
		return nil, err
	}
	if err := auth.ValidatePassword(req.Msg.GetNewPassword()); err != nil {
		return nil, connect.NewError(connect.CodeInvalidArgument, err)
	}
	if !auth.VerifyPassword(req.Msg.GetCurrentPassword(), user.PasswordHash, user.PasswordSalt) {
		return nil, connect.NewError(connect.CodePermissionDenied, errInvalid("current password is wrong"))
	}
	hash, salt, err := auth.HashPassword(req.Msg.GetNewPassword())
	if err != nil {
		return nil, connect.NewError(connect.CodeInternal, err)
	}
	if _, err := s.st.UpdateUser(user.ID, func(u *store.User) {
		u.PasswordHash = hash
		u.PasswordSalt = salt
	}); err != nil {
		return nil, connect.NewError(connect.CodeInternal, err)
	}
	// Other sessions are signed out; the caller's own token keeps working.
	s.st.DeleteUserSessions(user.ID, auth.TokenFrom(ctx))
	return connect.NewResponse(&ratatoskv1.ChangePasswordResponse{}), nil
}
