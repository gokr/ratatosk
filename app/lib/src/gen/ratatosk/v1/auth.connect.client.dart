//
//  Generated code. Do not modify.
//  source: ratatosk/v1/auth.proto
//

import "package:connectrpc/connect.dart" as connect;
import "auth.pb.dart" as ratatoskv1auth;
import "auth.connect.spec.dart" as specs;

/// Account creation, sign-in and profile management.
/// Register and Login are the only procedures that work without a bearer
/// token; everything else needs `Authorization: Bearer <token>`, which the
/// server resolves into the calling user.
extension type AuthServiceClient (connect.Transport _transport) {
  /// Create an account and return a session token.
  Future<ratatoskv1auth.RegisterResponse> register(
    ratatoskv1auth.RegisterRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.AuthService.register,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// Exchange username and password for a session token.
  Future<ratatoskv1auth.LoginResponse> login(
    ratatoskv1auth.LoginRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.AuthService.login,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// Revoke the token used for this call.
  Future<ratatoskv1auth.LogoutResponse> logout(
    ratatoskv1auth.LogoutRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.AuthService.logout,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// The calling user, refreshed (presence, profile edits).
  Future<ratatoskv1auth.GetMeResponse> getMe(
    ratatoskv1auth.GetMeRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.AuthService.getMe,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// Edit display name, bio, accent color or profile picture.
  Future<ratatoskv1auth.UpdateProfileResponse> updateProfile(
    ratatoskv1auth.UpdateProfileRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.AuthService.updateProfile,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// Rotate the password; other sessions stay valid.
  Future<ratatoskv1auth.ChangePasswordResponse> changePassword(
    ratatoskv1auth.ChangePasswordRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.AuthService.changePassword,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// Delete the calling account and everything that belongs to it.
  /// Requires the password to be repeated in the request: an action this
  /// destructive must not be reachable by anyone who merely has a live session
  /// (a shared laptop, a stolen token). It is the one irreversible thing a user
  /// can ask for, so the same check the operator's --delete-account does applies.
  Future<ratatoskv1auth.DeleteAccountResponse> deleteAccount(
    ratatoskv1auth.DeleteAccountRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.AuthService.deleteAccount,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// Turn a verified social sign-in into an account.
  /// Reached only through the server's own OAuth callback: the browser comes back
  /// with an opaque pending token, and the password (if any) is chosen here. An
  /// invitation is required, because this server is invite-only.
  Future<ratatoskv1auth.FinishGoogleSignUpResponse> finishGoogleSignUp(
    ratatoskv1auth.FinishGoogleSignUpRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.AuthService.finishGoogleSignUp,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// Whether this server offers Google sign-in at all, and the client id and
  /// callback the browser needs. Public: it is shown before anybody signs in.
  Future<ratatoskv1auth.GoogleSignInConfigResponse> googleSignInConfig(
    ratatoskv1auth.GoogleSignInConfigRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.AuthService.googleSignInConfig,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// The sign-in methods this account has, so Settings can show them.
  Future<ratatoskv1auth.SignInMethodsResponse> signInMethods(
    ratatoskv1auth.SignInMethodsRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.AuthService.signInMethods,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }
}
