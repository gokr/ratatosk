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
}
