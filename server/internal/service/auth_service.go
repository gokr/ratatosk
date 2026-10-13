package service

import (
	"context"
	"errors"

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

// DeleteAccount removes the caller's account and everything that belongs to it.
//
// The password is required again even though the caller is already
// authenticated: this is the one irreversible action in the product, and a live
// session is not the same thing as the person who owns the account (a shared
// laptop, a token lifted from a browser profile). Asking for the password turns
// "someone is signed in" into "the owner meant it".
//
// The deletion itself is the same store operation the operator's
// `--delete-account` uses, so the two paths cannot drift: a direct conversation
// goes with its messages, a group keeps its history minus this member, and
// sessions, device keys, envelopes, contacts, invites and attachments all go.
func (s *AuthService) DeleteAccount(ctx context.Context, req *connect.Request[ratatoskv1.DeleteAccountRequest]) (*connect.Response[ratatoskv1.DeleteAccountResponse], error) {
	user, err := s.requireUser(ctx)
	if err != nil {
		return nil, err
	}
	if !auth.VerifyPassword(req.Msg.GetPassword(), user.PasswordHash, user.PasswordSalt) {
		return nil, connect.NewError(connect.CodePermissionDenied,
			errInvalid("that password is not correct"))
	}

	summary, err := s.st.DeleteUser(user.ID)
	if err != nil {
		if errors.Is(err, store.ErrNotFound) {
			// Already gone (a double submit). Treat as success: the caller asked
			// for the account to not exist, and it does not.
			return connect.NewResponse(&ratatoskv1.DeleteAccountResponse{}), nil
		}
		return nil, connect.NewError(connect.CodeInternal, err)
	}

	s.log.Info("account deleted by its owner",
		"user", summary.UserID, "username", summary.Username,
		"directConversations", summary.DirectChats, "messages", summary.Messages,
		"attachments", summary.Attachments)
	return connect.NewResponse(&ratatoskv1.DeleteAccountResponse{
		ConversationsDeleted: int32(summary.DirectChats + summary.GroupMemberships),
		MessagesDeleted:      int32(summary.Messages),
		AttachmentsDeleted:   int32(summary.Attachments),
	}), nil
}

// FinishGoogleSignUp creates an account for a verified social identity.
//
// Invite-only and username-always, both by request: the account does not exist until
// an invitation has been proved and a handle chosen. Google established only *who*
// the person is, which is why this is a separate step rather than a quiet
// account creation inside the callback.
//
// The password is left empty on purpose. Every credential check therefore has to
// refuse an empty hash rather than compare it, which auth.VerifyPassword enforces —
// and which is tested, because the failure mode is an account open to any password.
func (s *AuthService) FinishGoogleSignUp(ctx context.Context, req *connect.Request[ratatoskv1.FinishGoogleSignUpRequest]) (*connect.Response[ratatoskv1.FinishGoogleSignUpResponse], error) {
	username := auth.NormalizeUsername(req.Msg.GetUsername())
	if err := auth.ValidateUsername(username); err != nil {
		return nil, connect.NewError(connect.CodeInvalidArgument, err)
	}
	displayName := trimSpace(req.Msg.GetDisplayName())
	if len(displayName) > 64 {
		return nil, connect.NewError(connect.CodeInvalidArgument,
			errInvalid("display name must be at most 64 characters"))
	}

	user, session, err := s.CompleteGoogleSignUp(ctx,
		req.Msg.GetPendingToken(), username, displayName, req.Msg.GetInviteCode())
	switch {
	case err == store.ErrUsernameTaken:
		return nil, connect.NewError(connect.CodeAlreadyExists, errInvalid("that username is taken"))
	case err != nil:
		return nil, connect.NewError(connect.CodeInvalidArgument, err)
	}

	// The veiled-identity prompt from the handshake still holds: this flow never
	// invents a device. A person who never opens an app is a registered account
	// with no keys, which is a real account in every respect.
	s.log.Info("google sign-up finished", "user", user.ID, "username", user.Username)
	return connect.NewResponse(&ratatoskv1.FinishGoogleSignUpResponse{
		Token:     session.Token,
		User:      s.userProto(user),
		ExpiresAt: ts(session.ExpiresAt),
	}), nil
}

// GoogleSignInConfig reports whether this server offers Google sign-in.
//
// Public, because the sign-in screen has to know before anybody is authenticated.
// The client id is not a secret: it is sent to Google in a URL by every site that
// uses it. The client secret is never mentioned here.
func (s *AuthService) GoogleSignInConfig(ctx context.Context, req *connect.Request[ratatoskv1.GoogleSignInConfigRequest]) (*connect.Response[ratatoskv1.GoogleSignInConfigResponse], error) {
	if s.cfg.GoogleClientID == "" {
		return connect.NewResponse(&ratatoskv1.GoogleSignInConfigResponse{Enabled: false}), nil
	}
	return connect.NewResponse(&ratatoskv1.GoogleSignInConfigResponse{
		Enabled:               true,
		ClientId:              s.cfg.GoogleClientID,
		AuthorizationEndpoint: normalPath(s.cfg.PublicURL, oauthStartPath),
		RedirectUri:           s.googleRedirectURI(),
	}), nil
}

// SignInMethods lists how an account can be reached.
//
// Shown in Settings because "which ways in do I have" is the question somebody asks
// *before* they need one, and an account whose only method is Google is a thing its
// owner should know.
func (s *AuthService) SignInMethods(ctx context.Context, req *connect.Request[ratatoskv1.SignInMethodsRequest]) (*connect.Response[ratatoskv1.SignInMethodsResponse], error) {
	user, err := s.requireUser(ctx)
	if err != nil {
		return nil, err
	}
	out := &ratatoskv1.SignInMethodsResponse{}
	if user.PasswordHash != "" {
		out.Methods = append(out.Methods, "password")
	}
	for _, link := range s.st.OAuthIdentitiesOf(user.ID) {
		if link.Provider == "google" {
			out.Methods = append(out.Methods, "google")
			out.GoogleEmail = link.Email
		}
	}
	return connect.NewResponse(out), nil
}

// googleRedirectURI is the absolute callback Google sends the browser back to.
func (s *AuthService) googleRedirectURI() string {
	return normalPath(s.cfg.PublicURL, oauthCallbackPath)
}
