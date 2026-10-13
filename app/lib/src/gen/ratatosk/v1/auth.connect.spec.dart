//
//  Generated code. Do not modify.
//  source: ratatosk/v1/auth.proto
//

import "package:connectrpc/connect.dart" as connect;
import "auth.pb.dart" as ratatoskv1auth;

/// Account creation, sign-in and profile management.
/// Register and Login are the only procedures that work without a bearer
/// token; everything else needs `Authorization: Bearer <token>`, which the
/// server resolves into the calling user.
abstract final class AuthService {
  /// Fully-qualified name of the AuthService service.
  static const name = 'ratatosk.v1.AuthService';

  /// Create an account and return a session token.
  static const register = connect.Spec(
    '/$name/Register',
    connect.StreamType.unary,
    ratatoskv1auth.RegisterRequest.new,
    ratatoskv1auth.RegisterResponse.new,
  );

  /// Exchange username and password for a session token.
  static const login = connect.Spec(
    '/$name/Login',
    connect.StreamType.unary,
    ratatoskv1auth.LoginRequest.new,
    ratatoskv1auth.LoginResponse.new,
  );

  /// Revoke the token used for this call.
  static const logout = connect.Spec(
    '/$name/Logout',
    connect.StreamType.unary,
    ratatoskv1auth.LogoutRequest.new,
    ratatoskv1auth.LogoutResponse.new,
  );

  /// The calling user, refreshed (presence, profile edits).
  static const getMe = connect.Spec(
    '/$name/GetMe',
    connect.StreamType.unary,
    ratatoskv1auth.GetMeRequest.new,
    ratatoskv1auth.GetMeResponse.new,
  );

  /// Edit display name, bio, accent color or profile picture.
  static const updateProfile = connect.Spec(
    '/$name/UpdateProfile',
    connect.StreamType.unary,
    ratatoskv1auth.UpdateProfileRequest.new,
    ratatoskv1auth.UpdateProfileResponse.new,
  );

  /// Rotate the password; other sessions stay valid.
  static const changePassword = connect.Spec(
    '/$name/ChangePassword',
    connect.StreamType.unary,
    ratatoskv1auth.ChangePasswordRequest.new,
    ratatoskv1auth.ChangePasswordResponse.new,
  );

  /// Delete the calling account and everything that belongs to it.
  /// Requires the password to be repeated in the request: an action this
  /// destructive must not be reachable by anyone who merely has a live session
  /// (a shared laptop, a stolen token). It is the one irreversible thing a user
  /// can ask for, so the same check the operator's --delete-account does applies.
  static const deleteAccount = connect.Spec(
    '/$name/DeleteAccount',
    connect.StreamType.unary,
    ratatoskv1auth.DeleteAccountRequest.new,
    ratatoskv1auth.DeleteAccountResponse.new,
  );

  /// Turn a verified social sign-in into an account.
  /// Reached only through the server's own OAuth callback: the browser comes back
  /// with an opaque pending token, and the password (if any) is chosen here. An
  /// invitation is required, because this server is invite-only.
  static const finishGoogleSignUp = connect.Spec(
    '/$name/FinishGoogleSignUp',
    connect.StreamType.unary,
    ratatoskv1auth.FinishGoogleSignUpRequest.new,
    ratatoskv1auth.FinishGoogleSignUpResponse.new,
  );

  /// Whether this server offers Google sign-in at all, and the client id and
  /// callback the browser needs. Public: it is shown before anybody signs in.
  static const googleSignInConfig = connect.Spec(
    '/$name/GoogleSignInConfig',
    connect.StreamType.unary,
    ratatoskv1auth.GoogleSignInConfigRequest.new,
    ratatoskv1auth.GoogleSignInConfigResponse.new,
  );

  /// The sign-in methods this account has, so Settings can show them.
  static const signInMethods = connect.Spec(
    '/$name/SignInMethods',
    connect.StreamType.unary,
    ratatoskv1auth.SignInMethodsRequest.new,
    ratatoskv1auth.SignInMethodsResponse.new,
  );
}
