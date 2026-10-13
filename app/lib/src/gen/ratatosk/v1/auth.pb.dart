// This is a generated file - do not edit.
//
// Generated from ratatosk/v1/auth.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart'
    as $1;

import 'common.pb.dart' as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class RegisterRequest extends $pb.GeneratedMessage {
  factory RegisterRequest({
    $core.String? username,
    $core.String? password,
    $core.String? displayName,
  }) {
    final result = RegisterRequest._();
    if (username != null) result.username = username;
    if (password != null) result.password = password;
    if (displayName != null) result.displayName = displayName;
    return result;
  }

  RegisterRequest._();

  factory RegisterRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RegisterRequest()..mergeFromBuffer(data, registry);
  factory RegisterRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RegisterRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RegisterRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: RegisterRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'username')
    ..aOS(2, _omitFieldNames ? '' : 'password')
    ..aOS(3, _omitFieldNames ? '' : 'displayName')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RegisterRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RegisterRequest copyWith(void Function(RegisterRequest) updates) =>
      super.copyWith((message) => updates(message as RegisterRequest))
          as RegisterRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RegisterRequest() / RegisterRequest.new instead')
  static RegisterRequest create() => RegisterRequest._();
  static $pb.GeneratedMessage $_createMessage() => RegisterRequest._();
  @$core.override
  RegisterRequest createEmptyInstance() => RegisterRequest._();
  @$core.pragma('dart2js:noInline')
  static RegisterRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RegisterRequest>(
          RegisterRequest.$_createMessage);
  static RegisterRequest? _defaultInstance;

  /// 3-32 chars, lowercase letters, digits, ".", "_" or "-".
  @$pb.TagNumber(1)
  $core.String get username => $_getSZ(0);
  @$pb.TagNumber(1)
  set username($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUsername() => $_has(0);
  @$pb.TagNumber(1)
  void clearUsername() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get password => $_getSZ(1);
  @$pb.TagNumber(2)
  set password($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPassword() => $_has(1);
  @$pb.TagNumber(2)
  void clearPassword() => $_clearField(2);

  /// Defaults to the username when empty.
  @$pb.TagNumber(3)
  $core.String get displayName => $_getSZ(2);
  @$pb.TagNumber(3)
  set displayName($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDisplayName() => $_has(2);
  @$pb.TagNumber(3)
  void clearDisplayName() => $_clearField(3);
}

class RegisterResponse extends $pb.GeneratedMessage {
  factory RegisterResponse({
    $core.String? token,
    $0.User? user,
    $1.Timestamp? expiresAt,
  }) {
    final result = RegisterResponse._();
    if (token != null) result.token = token;
    if (user != null) result.user = user;
    if (expiresAt != null) result.expiresAt = expiresAt;
    return result;
  }

  RegisterResponse._();

  factory RegisterResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RegisterResponse()..mergeFromBuffer(data, registry);
  factory RegisterResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RegisterResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RegisterResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: RegisterResponse.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'token')
    ..aOM<$0.User>(2, _omitFieldNames ? '' : 'user',
        subBuilder: $0.User.$_createMessage)
    ..aOM<$1.Timestamp>(3, _omitFieldNames ? '' : 'expiresAt',
        subBuilder: $1.Timestamp.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RegisterResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RegisterResponse copyWith(void Function(RegisterResponse) updates) =>
      super.copyWith((message) => updates(message as RegisterResponse))
          as RegisterResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RegisterResponse() / RegisterResponse.new instead')
  static RegisterResponse create() => RegisterResponse._();
  static $pb.GeneratedMessage $_createMessage() => RegisterResponse._();
  @$core.override
  RegisterResponse createEmptyInstance() => RegisterResponse._();
  @$core.pragma('dart2js:noInline')
  static RegisterResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RegisterResponse>(
          RegisterResponse.$_createMessage);
  static RegisterResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get token => $_getSZ(0);
  @$pb.TagNumber(1)
  set token($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasToken() => $_has(0);
  @$pb.TagNumber(1)
  void clearToken() => $_clearField(1);

  @$pb.TagNumber(2)
  $0.User get user => $_getN(1);
  @$pb.TagNumber(2)
  set user($0.User value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasUser() => $_has(1);
  @$pb.TagNumber(2)
  void clearUser() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.User ensureUser() => $_ensure(1);

  @$pb.TagNumber(3)
  $1.Timestamp get expiresAt => $_getN(2);
  @$pb.TagNumber(3)
  set expiresAt($1.Timestamp value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasExpiresAt() => $_has(2);
  @$pb.TagNumber(3)
  void clearExpiresAt() => $_clearField(3);
  @$pb.TagNumber(3)
  $1.Timestamp ensureExpiresAt() => $_ensure(2);
}

class LoginRequest extends $pb.GeneratedMessage {
  factory LoginRequest({
    $core.String? username,
    $core.String? password,
  }) {
    final result = LoginRequest._();
    if (username != null) result.username = username;
    if (password != null) result.password = password;
    return result;
  }

  LoginRequest._();

  factory LoginRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LoginRequest()..mergeFromBuffer(data, registry);
  factory LoginRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LoginRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LoginRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: LoginRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'username')
    ..aOS(2, _omitFieldNames ? '' : 'password')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LoginRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LoginRequest copyWith(void Function(LoginRequest) updates) =>
      super.copyWith((message) => updates(message as LoginRequest))
          as LoginRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use LoginRequest() / LoginRequest.new instead')
  static LoginRequest create() => LoginRequest._();
  static $pb.GeneratedMessage $_createMessage() => LoginRequest._();
  @$core.override
  LoginRequest createEmptyInstance() => LoginRequest._();
  @$core.pragma('dart2js:noInline')
  static LoginRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LoginRequest>(
          LoginRequest.$_createMessage);
  static LoginRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get username => $_getSZ(0);
  @$pb.TagNumber(1)
  set username($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUsername() => $_has(0);
  @$pb.TagNumber(1)
  void clearUsername() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get password => $_getSZ(1);
  @$pb.TagNumber(2)
  set password($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPassword() => $_has(1);
  @$pb.TagNumber(2)
  void clearPassword() => $_clearField(2);
}

class LoginResponse extends $pb.GeneratedMessage {
  factory LoginResponse({
    $core.String? token,
    $0.User? user,
    $1.Timestamp? expiresAt,
  }) {
    final result = LoginResponse._();
    if (token != null) result.token = token;
    if (user != null) result.user = user;
    if (expiresAt != null) result.expiresAt = expiresAt;
    return result;
  }

  LoginResponse._();

  factory LoginResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LoginResponse()..mergeFromBuffer(data, registry);
  factory LoginResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LoginResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LoginResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: LoginResponse.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'token')
    ..aOM<$0.User>(2, _omitFieldNames ? '' : 'user',
        subBuilder: $0.User.$_createMessage)
    ..aOM<$1.Timestamp>(3, _omitFieldNames ? '' : 'expiresAt',
        subBuilder: $1.Timestamp.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LoginResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LoginResponse copyWith(void Function(LoginResponse) updates) =>
      super.copyWith((message) => updates(message as LoginResponse))
          as LoginResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use LoginResponse() / LoginResponse.new instead')
  static LoginResponse create() => LoginResponse._();
  static $pb.GeneratedMessage $_createMessage() => LoginResponse._();
  @$core.override
  LoginResponse createEmptyInstance() => LoginResponse._();
  @$core.pragma('dart2js:noInline')
  static LoginResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LoginResponse>(
          LoginResponse.$_createMessage);
  static LoginResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get token => $_getSZ(0);
  @$pb.TagNumber(1)
  set token($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasToken() => $_has(0);
  @$pb.TagNumber(1)
  void clearToken() => $_clearField(1);

  @$pb.TagNumber(2)
  $0.User get user => $_getN(1);
  @$pb.TagNumber(2)
  set user($0.User value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasUser() => $_has(1);
  @$pb.TagNumber(2)
  void clearUser() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.User ensureUser() => $_ensure(1);

  @$pb.TagNumber(3)
  $1.Timestamp get expiresAt => $_getN(2);
  @$pb.TagNumber(3)
  set expiresAt($1.Timestamp value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasExpiresAt() => $_has(2);
  @$pb.TagNumber(3)
  void clearExpiresAt() => $_clearField(3);
  @$pb.TagNumber(3)
  $1.Timestamp ensureExpiresAt() => $_ensure(2);
}

class LogoutRequest extends $pb.GeneratedMessage {
  factory LogoutRequest() => LogoutRequest._();

  LogoutRequest._();

  factory LogoutRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LogoutRequest()..mergeFromBuffer(data, registry);
  factory LogoutRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LogoutRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LogoutRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: LogoutRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LogoutRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LogoutRequest copyWith(void Function(LogoutRequest) updates) =>
      super.copyWith((message) => updates(message as LogoutRequest))
          as LogoutRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use LogoutRequest() / LogoutRequest.new instead')
  static LogoutRequest create() => LogoutRequest._();
  static $pb.GeneratedMessage $_createMessage() => LogoutRequest._();
  @$core.override
  LogoutRequest createEmptyInstance() => LogoutRequest._();
  @$core.pragma('dart2js:noInline')
  static LogoutRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LogoutRequest>(
          LogoutRequest.$_createMessage);
  static LogoutRequest? _defaultInstance;
}

class LogoutResponse extends $pb.GeneratedMessage {
  factory LogoutResponse() => LogoutResponse._();

  LogoutResponse._();

  factory LogoutResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LogoutResponse()..mergeFromBuffer(data, registry);
  factory LogoutResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LogoutResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LogoutResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: LogoutResponse.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LogoutResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LogoutResponse copyWith(void Function(LogoutResponse) updates) =>
      super.copyWith((message) => updates(message as LogoutResponse))
          as LogoutResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use LogoutResponse() / LogoutResponse.new instead')
  static LogoutResponse create() => LogoutResponse._();
  static $pb.GeneratedMessage $_createMessage() => LogoutResponse._();
  @$core.override
  LogoutResponse createEmptyInstance() => LogoutResponse._();
  @$core.pragma('dart2js:noInline')
  static LogoutResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LogoutResponse>(
          LogoutResponse.$_createMessage);
  static LogoutResponse? _defaultInstance;
}

class GetMeRequest extends $pb.GeneratedMessage {
  factory GetMeRequest() => GetMeRequest._();

  GetMeRequest._();

  factory GetMeRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetMeRequest()..mergeFromBuffer(data, registry);
  factory GetMeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetMeRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetMeRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: GetMeRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetMeRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetMeRequest copyWith(void Function(GetMeRequest) updates) =>
      super.copyWith((message) => updates(message as GetMeRequest))
          as GetMeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetMeRequest() / GetMeRequest.new instead')
  static GetMeRequest create() => GetMeRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetMeRequest._();
  @$core.override
  GetMeRequest createEmptyInstance() => GetMeRequest._();
  @$core.pragma('dart2js:noInline')
  static GetMeRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetMeRequest>(
          GetMeRequest.$_createMessage);
  static GetMeRequest? _defaultInstance;
}

class GetMeResponse extends $pb.GeneratedMessage {
  factory GetMeResponse({
    $0.User? user,
  }) {
    final result = GetMeResponse._();
    if (user != null) result.user = user;
    return result;
  }

  GetMeResponse._();

  factory GetMeResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetMeResponse()..mergeFromBuffer(data, registry);
  factory GetMeResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetMeResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetMeResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: GetMeResponse.$_createMessage)
    ..aOM<$0.User>(1, _omitFieldNames ? '' : 'user',
        subBuilder: $0.User.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetMeResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetMeResponse copyWith(void Function(GetMeResponse) updates) =>
      super.copyWith((message) => updates(message as GetMeResponse))
          as GetMeResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetMeResponse() / GetMeResponse.new instead')
  static GetMeResponse create() => GetMeResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetMeResponse._();
  @$core.override
  GetMeResponse createEmptyInstance() => GetMeResponse._();
  @$core.pragma('dart2js:noInline')
  static GetMeResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetMeResponse>(
          GetMeResponse.$_createMessage);
  static GetMeResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $0.User get user => $_getN(0);
  @$pb.TagNumber(1)
  set user($0.User value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasUser() => $_has(0);
  @$pb.TagNumber(1)
  void clearUser() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.User ensureUser() => $_ensure(0);
}

class UpdateProfileRequest extends $pb.GeneratedMessage {
  factory UpdateProfileRequest({
    $core.String? displayName,
    $core.String? bio,
    $core.String? avatarAttachmentId,
    $core.String? accentColor,
    $core.bool? clearAvatar,
  }) {
    final result = UpdateProfileRequest._();
    if (displayName != null) result.displayName = displayName;
    if (bio != null) result.bio = bio;
    if (avatarAttachmentId != null)
      result.avatarAttachmentId = avatarAttachmentId;
    if (accentColor != null) result.accentColor = accentColor;
    if (clearAvatar != null) result.clearAvatar = clearAvatar;
    return result;
  }

  UpdateProfileRequest._();

  factory UpdateProfileRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UpdateProfileRequest()..mergeFromBuffer(data, registry);
  factory UpdateProfileRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UpdateProfileRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateProfileRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: UpdateProfileRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'displayName')
    ..aOS(2, _omitFieldNames ? '' : 'bio')
    ..aOS(3, _omitFieldNames ? '' : 'avatarAttachmentId')
    ..aOS(4, _omitFieldNames ? '' : 'accentColor')
    ..aOB(5, _omitFieldNames ? '' : 'clearAvatar')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateProfileRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateProfileRequest copyWith(void Function(UpdateProfileRequest) updates) =>
      super.copyWith((message) => updates(message as UpdateProfileRequest))
          as UpdateProfileRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use UpdateProfileRequest() / UpdateProfileRequest.new instead')
  static UpdateProfileRequest create() => UpdateProfileRequest._();
  static $pb.GeneratedMessage $_createMessage() => UpdateProfileRequest._();
  @$core.override
  UpdateProfileRequest createEmptyInstance() => UpdateProfileRequest._();
  @$core.pragma('dart2js:noInline')
  static UpdateProfileRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateProfileRequest>(
          UpdateProfileRequest.$_createMessage);
  static UpdateProfileRequest? _defaultInstance;

  /// Empty keeps the current value.
  @$pb.TagNumber(1)
  $core.String get displayName => $_getSZ(0);
  @$pb.TagNumber(1)
  set displayName($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDisplayName() => $_has(0);
  @$pb.TagNumber(1)
  void clearDisplayName() => $_clearField(1);

  /// Optional so that clearing the bio is expressible; absent keeps it.
  @$pb.TagNumber(2)
  $core.String get bio => $_getSZ(1);
  @$pb.TagNumber(2)
  set bio($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasBio() => $_has(1);
  @$pb.TagNumber(2)
  void clearBio() => $_clearField(2);

  /// Attachment id from ChatService.UploadAttachment; empty keeps the current
  /// picture.
  @$pb.TagNumber(3)
  $core.String get avatarAttachmentId => $_getSZ(2);
  @$pb.TagNumber(3)
  set avatarAttachmentId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAvatarAttachmentId() => $_has(2);
  @$pb.TagNumber(3)
  void clearAvatarAttachmentId() => $_clearField(3);

  /// Hex color like "#0084ff"; empty keeps the current color.
  @$pb.TagNumber(4)
  $core.String get accentColor => $_getSZ(3);
  @$pb.TagNumber(4)
  set accentColor($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAccentColor() => $_has(3);
  @$pb.TagNumber(4)
  void clearAccentColor() => $_clearField(4);

  /// Remove the current profile picture.
  @$pb.TagNumber(5)
  $core.bool get clearAvatar => $_getBF(4);
  @$pb.TagNumber(5)
  set clearAvatar($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasClearAvatar() => $_has(4);
  @$pb.TagNumber(5)
  void clearClearAvatar() => $_clearField(5);
}

class UpdateProfileResponse extends $pb.GeneratedMessage {
  factory UpdateProfileResponse({
    $0.User? user,
  }) {
    final result = UpdateProfileResponse._();
    if (user != null) result.user = user;
    return result;
  }

  UpdateProfileResponse._();

  factory UpdateProfileResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UpdateProfileResponse()..mergeFromBuffer(data, registry);
  factory UpdateProfileResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UpdateProfileResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateProfileResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: UpdateProfileResponse.$_createMessage)
    ..aOM<$0.User>(1, _omitFieldNames ? '' : 'user',
        subBuilder: $0.User.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateProfileResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateProfileResponse copyWith(
          void Function(UpdateProfileResponse) updates) =>
      super.copyWith((message) => updates(message as UpdateProfileResponse))
          as UpdateProfileResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use UpdateProfileResponse() / UpdateProfileResponse.new instead')
  static UpdateProfileResponse create() => UpdateProfileResponse._();
  static $pb.GeneratedMessage $_createMessage() => UpdateProfileResponse._();
  @$core.override
  UpdateProfileResponse createEmptyInstance() => UpdateProfileResponse._();
  @$core.pragma('dart2js:noInline')
  static UpdateProfileResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateProfileResponse>(
          UpdateProfileResponse.$_createMessage);
  static UpdateProfileResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $0.User get user => $_getN(0);
  @$pb.TagNumber(1)
  set user($0.User value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasUser() => $_has(0);
  @$pb.TagNumber(1)
  void clearUser() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.User ensureUser() => $_ensure(0);
}

class ChangePasswordRequest extends $pb.GeneratedMessage {
  factory ChangePasswordRequest({
    $core.String? currentPassword,
    $core.String? newPassword,
  }) {
    final result = ChangePasswordRequest._();
    if (currentPassword != null) result.currentPassword = currentPassword;
    if (newPassword != null) result.newPassword = newPassword;
    return result;
  }

  ChangePasswordRequest._();

  factory ChangePasswordRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ChangePasswordRequest()..mergeFromBuffer(data, registry);
  factory ChangePasswordRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ChangePasswordRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ChangePasswordRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: ChangePasswordRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'currentPassword')
    ..aOS(2, _omitFieldNames ? '' : 'newPassword')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChangePasswordRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChangePasswordRequest copyWith(
          void Function(ChangePasswordRequest) updates) =>
      super.copyWith((message) => updates(message as ChangePasswordRequest))
          as ChangePasswordRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ChangePasswordRequest() / ChangePasswordRequest.new instead')
  static ChangePasswordRequest create() => ChangePasswordRequest._();
  static $pb.GeneratedMessage $_createMessage() => ChangePasswordRequest._();
  @$core.override
  ChangePasswordRequest createEmptyInstance() => ChangePasswordRequest._();
  @$core.pragma('dart2js:noInline')
  static ChangePasswordRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ChangePasswordRequest>(
          ChangePasswordRequest.$_createMessage);
  static ChangePasswordRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get currentPassword => $_getSZ(0);
  @$pb.TagNumber(1)
  set currentPassword($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCurrentPassword() => $_has(0);
  @$pb.TagNumber(1)
  void clearCurrentPassword() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get newPassword => $_getSZ(1);
  @$pb.TagNumber(2)
  set newPassword($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNewPassword() => $_has(1);
  @$pb.TagNumber(2)
  void clearNewPassword() => $_clearField(2);
}

class ChangePasswordResponse extends $pb.GeneratedMessage {
  factory ChangePasswordResponse() => ChangePasswordResponse._();

  ChangePasswordResponse._();

  factory ChangePasswordResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ChangePasswordResponse()..mergeFromBuffer(data, registry);
  factory ChangePasswordResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ChangePasswordResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ChangePasswordResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: ChangePasswordResponse.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChangePasswordResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChangePasswordResponse copyWith(
          void Function(ChangePasswordResponse) updates) =>
      super.copyWith((message) => updates(message as ChangePasswordResponse))
          as ChangePasswordResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ChangePasswordResponse() / ChangePasswordResponse.new instead')
  static ChangePasswordResponse create() => ChangePasswordResponse._();
  static $pb.GeneratedMessage $_createMessage() => ChangePasswordResponse._();
  @$core.override
  ChangePasswordResponse createEmptyInstance() => ChangePasswordResponse._();
  @$core.pragma('dart2js:noInline')
  static ChangePasswordResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ChangePasswordResponse>(
          ChangePasswordResponse.$_createMessage);
  static ChangePasswordResponse? _defaultInstance;
}

class DeleteAccountRequest extends $pb.GeneratedMessage {
  factory DeleteAccountRequest({
    $core.String? password,
  }) {
    final result = DeleteAccountRequest._();
    if (password != null) result.password = password;
    return result;
  }

  DeleteAccountRequest._();

  factory DeleteAccountRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeleteAccountRequest()..mergeFromBuffer(data, registry);
  factory DeleteAccountRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeleteAccountRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteAccountRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: DeleteAccountRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'password')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteAccountRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteAccountRequest copyWith(void Function(DeleteAccountRequest) updates) =>
      super.copyWith((message) => updates(message as DeleteAccountRequest))
          as DeleteAccountRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use DeleteAccountRequest() / DeleteAccountRequest.new instead')
  static DeleteAccountRequest create() => DeleteAccountRequest._();
  static $pb.GeneratedMessage $_createMessage() => DeleteAccountRequest._();
  @$core.override
  DeleteAccountRequest createEmptyInstance() => DeleteAccountRequest._();
  @$core.pragma('dart2js:noInline')
  static DeleteAccountRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteAccountRequest>(
          DeleteAccountRequest.$_createMessage);
  static DeleteAccountRequest? _defaultInstance;

  /// The caller's password. Confirms intent rather than merely proving identity.
  @$pb.TagNumber(1)
  $core.String get password => $_getSZ(0);
  @$pb.TagNumber(1)
  set password($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPassword() => $_has(0);
  @$pb.TagNumber(1)
  void clearPassword() => $_clearField(1);
}

class DeleteAccountResponse extends $pb.GeneratedMessage {
  factory DeleteAccountResponse({
    $core.int? conversationsDeleted,
    $core.int? messagesDeleted,
    $core.int? attachmentsDeleted,
  }) {
    final result = DeleteAccountResponse._();
    if (conversationsDeleted != null)
      result.conversationsDeleted = conversationsDeleted;
    if (messagesDeleted != null) result.messagesDeleted = messagesDeleted;
    if (attachmentsDeleted != null)
      result.attachmentsDeleted = attachmentsDeleted;
    return result;
  }

  DeleteAccountResponse._();

  factory DeleteAccountResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeleteAccountResponse()..mergeFromBuffer(data, registry);
  factory DeleteAccountResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeleteAccountResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteAccountResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: DeleteAccountResponse.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'conversationsDeleted')
    ..aI(2, _omitFieldNames ? '' : 'messagesDeleted')
    ..aI(3, _omitFieldNames ? '' : 'attachmentsDeleted')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteAccountResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteAccountResponse copyWith(
          void Function(DeleteAccountResponse) updates) =>
      super.copyWith((message) => updates(message as DeleteAccountResponse))
          as DeleteAccountResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use DeleteAccountResponse() / DeleteAccountResponse.new instead')
  static DeleteAccountResponse create() => DeleteAccountResponse._();
  static $pb.GeneratedMessage $_createMessage() => DeleteAccountResponse._();
  @$core.override
  DeleteAccountResponse createEmptyInstance() => DeleteAccountResponse._();
  @$core.pragma('dart2js:noInline')
  static DeleteAccountResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteAccountResponse>(
          DeleteAccountResponse.$_createMessage);
  static DeleteAccountResponse? _defaultInstance;

  /// What the deletion removed, so the app can state it rather than assert it.
  /// The server does not report counts it did not actually delete.
  @$pb.TagNumber(1)
  $core.int get conversationsDeleted => $_getIZ(0);
  @$pb.TagNumber(1)
  set conversationsDeleted($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasConversationsDeleted() => $_has(0);
  @$pb.TagNumber(1)
  void clearConversationsDeleted() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get messagesDeleted => $_getIZ(1);
  @$pb.TagNumber(2)
  set messagesDeleted($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessagesDeleted() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessagesDeleted() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get attachmentsDeleted => $_getIZ(2);
  @$pb.TagNumber(3)
  set attachmentsDeleted($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAttachmentsDeleted() => $_has(2);
  @$pb.TagNumber(3)
  void clearAttachmentsDeleted() => $_clearField(3);
}

class FinishGoogleSignUpRequest extends $pb.GeneratedMessage {
  factory FinishGoogleSignUpRequest({
    $core.String? pendingToken,
    $core.String? username,
    $core.String? displayName,
    $core.String? inviteCode,
  }) {
    final result = FinishGoogleSignUpRequest._();
    if (pendingToken != null) result.pendingToken = pendingToken;
    if (username != null) result.username = username;
    if (displayName != null) result.displayName = displayName;
    if (inviteCode != null) result.inviteCode = inviteCode;
    return result;
  }

  FinishGoogleSignUpRequest._();

  factory FinishGoogleSignUpRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      FinishGoogleSignUpRequest()..mergeFromBuffer(data, registry);
  factory FinishGoogleSignUpRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      FinishGoogleSignUpRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FinishGoogleSignUpRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: FinishGoogleSignUpRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'pendingToken')
    ..aOS(2, _omitFieldNames ? '' : 'username')
    ..aOS(3, _omitFieldNames ? '' : 'displayName')
    ..aOS(4, _omitFieldNames ? '' : 'inviteCode')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FinishGoogleSignUpRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FinishGoogleSignUpRequest copyWith(
          void Function(FinishGoogleSignUpRequest) updates) =>
      super.copyWith((message) => updates(message as FinishGoogleSignUpRequest))
          as FinishGoogleSignUpRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use FinishGoogleSignUpRequest() / FinishGoogleSignUpRequest.new instead')
  static FinishGoogleSignUpRequest create() => FinishGoogleSignUpRequest._();
  static $pb.GeneratedMessage $_createMessage() =>
      FinishGoogleSignUpRequest._();
  @$core.override
  FinishGoogleSignUpRequest createEmptyInstance() =>
      FinishGoogleSignUpRequest._();
  @$core.pragma('dart2js:noInline')
  static FinishGoogleSignUpRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FinishGoogleSignUpRequest>(
          FinishGoogleSignUpRequest.$_createMessage);
  static FinishGoogleSignUpRequest? _defaultInstance;

  /// The opaque token the OAuth callback handed the app.
  @$pb.TagNumber(1)
  $core.String get pendingToken => $_getSZ(0);
  @$pb.TagNumber(1)
  set pendingToken($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPendingToken() => $_has(0);
  @$pb.TagNumber(1)
  void clearPendingToken() => $_clearField(1);

  /// Required: every account has a username, chosen by its owner.
  @$pb.TagNumber(2)
  $core.String get username => $_getSZ(1);
  @$pb.TagNumber(2)
  set username($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUsername() => $_has(1);
  @$pb.TagNumber(2)
  void clearUsername() => $_clearField(2);

  /// Defaults to what the provider told us.
  @$pb.TagNumber(3)
  $core.String get displayName => $_getSZ(2);
  @$pb.TagNumber(3)
  set displayName($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDisplayName() => $_has(2);
  @$pb.TagNumber(3)
  void clearDisplayName() => $_clearField(3);

  /// Required: this server is invite-only.
  @$pb.TagNumber(4)
  $core.String get inviteCode => $_getSZ(3);
  @$pb.TagNumber(4)
  set inviteCode($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasInviteCode() => $_has(3);
  @$pb.TagNumber(4)
  void clearInviteCode() => $_clearField(4);
}

class FinishGoogleSignUpResponse extends $pb.GeneratedMessage {
  factory FinishGoogleSignUpResponse({
    $core.String? token,
    $0.User? user,
    $1.Timestamp? expiresAt,
  }) {
    final result = FinishGoogleSignUpResponse._();
    if (token != null) result.token = token;
    if (user != null) result.user = user;
    if (expiresAt != null) result.expiresAt = expiresAt;
    return result;
  }

  FinishGoogleSignUpResponse._();

  factory FinishGoogleSignUpResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      FinishGoogleSignUpResponse()..mergeFromBuffer(data, registry);
  factory FinishGoogleSignUpResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      FinishGoogleSignUpResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FinishGoogleSignUpResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: FinishGoogleSignUpResponse.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'token')
    ..aOM<$0.User>(2, _omitFieldNames ? '' : 'user',
        subBuilder: $0.User.$_createMessage)
    ..aOM<$1.Timestamp>(3, _omitFieldNames ? '' : 'expiresAt',
        subBuilder: $1.Timestamp.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FinishGoogleSignUpResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FinishGoogleSignUpResponse copyWith(
          void Function(FinishGoogleSignUpResponse) updates) =>
      super.copyWith(
              (message) => updates(message as FinishGoogleSignUpResponse))
          as FinishGoogleSignUpResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use FinishGoogleSignUpResponse() / FinishGoogleSignUpResponse.new instead')
  static FinishGoogleSignUpResponse create() => FinishGoogleSignUpResponse._();
  static $pb.GeneratedMessage $_createMessage() =>
      FinishGoogleSignUpResponse._();
  @$core.override
  FinishGoogleSignUpResponse createEmptyInstance() =>
      FinishGoogleSignUpResponse._();
  @$core.pragma('dart2js:noInline')
  static FinishGoogleSignUpResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FinishGoogleSignUpResponse>(
          FinishGoogleSignUpResponse.$_createMessage);
  static FinishGoogleSignUpResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get token => $_getSZ(0);
  @$pb.TagNumber(1)
  set token($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasToken() => $_has(0);
  @$pb.TagNumber(1)
  void clearToken() => $_clearField(1);

  @$pb.TagNumber(2)
  $0.User get user => $_getN(1);
  @$pb.TagNumber(2)
  set user($0.User value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasUser() => $_has(1);
  @$pb.TagNumber(2)
  void clearUser() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.User ensureUser() => $_ensure(1);

  @$pb.TagNumber(3)
  $1.Timestamp get expiresAt => $_getN(2);
  @$pb.TagNumber(3)
  set expiresAt($1.Timestamp value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasExpiresAt() => $_has(2);
  @$pb.TagNumber(3)
  void clearExpiresAt() => $_clearField(3);
  @$pb.TagNumber(3)
  $1.Timestamp ensureExpiresAt() => $_ensure(2);
}

class GoogleSignInConfigRequest extends $pb.GeneratedMessage {
  factory GoogleSignInConfigRequest() => GoogleSignInConfigRequest._();

  GoogleSignInConfigRequest._();

  factory GoogleSignInConfigRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GoogleSignInConfigRequest()..mergeFromBuffer(data, registry);
  factory GoogleSignInConfigRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GoogleSignInConfigRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GoogleSignInConfigRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: GoogleSignInConfigRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GoogleSignInConfigRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GoogleSignInConfigRequest copyWith(
          void Function(GoogleSignInConfigRequest) updates) =>
      super.copyWith((message) => updates(message as GoogleSignInConfigRequest))
          as GoogleSignInConfigRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GoogleSignInConfigRequest() / GoogleSignInConfigRequest.new instead')
  static GoogleSignInConfigRequest create() => GoogleSignInConfigRequest._();
  static $pb.GeneratedMessage $_createMessage() =>
      GoogleSignInConfigRequest._();
  @$core.override
  GoogleSignInConfigRequest createEmptyInstance() =>
      GoogleSignInConfigRequest._();
  @$core.pragma('dart2js:noInline')
  static GoogleSignInConfigRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GoogleSignInConfigRequest>(
          GoogleSignInConfigRequest.$_createMessage);
  static GoogleSignInConfigRequest? _defaultInstance;
}

class GoogleSignInConfigResponse extends $pb.GeneratedMessage {
  factory GoogleSignInConfigResponse({
    $core.bool? enabled,
    $core.String? clientId,
    $core.String? authorizationEndpoint,
    $core.String? redirectUri,
  }) {
    final result = GoogleSignInConfigResponse._();
    if (enabled != null) result.enabled = enabled;
    if (clientId != null) result.clientId = clientId;
    if (authorizationEndpoint != null)
      result.authorizationEndpoint = authorizationEndpoint;
    if (redirectUri != null) result.redirectUri = redirectUri;
    return result;
  }

  GoogleSignInConfigResponse._();

  factory GoogleSignInConfigResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GoogleSignInConfigResponse()..mergeFromBuffer(data, registry);
  factory GoogleSignInConfigResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GoogleSignInConfigResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GoogleSignInConfigResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: GoogleSignInConfigResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'enabled')
    ..aOS(2, _omitFieldNames ? '' : 'clientId')
    ..aOS(3, _omitFieldNames ? '' : 'authorizationEndpoint')
    ..aOS(4, _omitFieldNames ? '' : 'redirectUri')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GoogleSignInConfigResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GoogleSignInConfigResponse copyWith(
          void Function(GoogleSignInConfigResponse) updates) =>
      super.copyWith(
              (message) => updates(message as GoogleSignInConfigResponse))
          as GoogleSignInConfigResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GoogleSignInConfigResponse() / GoogleSignInConfigResponse.new instead')
  static GoogleSignInConfigResponse create() => GoogleSignInConfigResponse._();
  static $pb.GeneratedMessage $_createMessage() =>
      GoogleSignInConfigResponse._();
  @$core.override
  GoogleSignInConfigResponse createEmptyInstance() =>
      GoogleSignInConfigResponse._();
  @$core.pragma('dart2js:noInline')
  static GoogleSignInConfigResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GoogleSignInConfigResponse>(
          GoogleSignInConfigResponse.$_createMessage);
  static GoogleSignInConfigResponse? _defaultInstance;

  /// False when no client id is configured; the client hides the button.
  @$pb.TagNumber(1)
  $core.bool get enabled => $_getBF(0);
  @$pb.TagNumber(1)
  set enabled($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEnabled() => $_has(0);
  @$pb.TagNumber(1)
  void clearEnabled() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get clientId => $_getSZ(1);
  @$pb.TagNumber(2)
  set clientId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasClientId() => $_has(1);
  @$pb.TagNumber(2)
  void clearClientId() => $_clearField(2);

  /// Absolute URL the client sends the browser to.
  @$pb.TagNumber(3)
  $core.String get authorizationEndpoint => $_getSZ(2);
  @$pb.TagNumber(3)
  set authorizationEndpoint($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAuthorizationEndpoint() => $_has(2);
  @$pb.TagNumber(3)
  void clearAuthorizationEndpoint() => $_clearField(3);

  /// Where Google sends the browser back to.
  @$pb.TagNumber(4)
  $core.String get redirectUri => $_getSZ(3);
  @$pb.TagNumber(4)
  set redirectUri($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasRedirectUri() => $_has(3);
  @$pb.TagNumber(4)
  void clearRedirectUri() => $_clearField(4);
}

class SignInMethodsRequest extends $pb.GeneratedMessage {
  factory SignInMethodsRequest() => SignInMethodsRequest._();

  SignInMethodsRequest._();

  factory SignInMethodsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SignInMethodsRequest()..mergeFromBuffer(data, registry);
  factory SignInMethodsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SignInMethodsRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SignInMethodsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: SignInMethodsRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SignInMethodsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SignInMethodsRequest copyWith(void Function(SignInMethodsRequest) updates) =>
      super.copyWith((message) => updates(message as SignInMethodsRequest))
          as SignInMethodsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SignInMethodsRequest() / SignInMethodsRequest.new instead')
  static SignInMethodsRequest create() => SignInMethodsRequest._();
  static $pb.GeneratedMessage $_createMessage() => SignInMethodsRequest._();
  @$core.override
  SignInMethodsRequest createEmptyInstance() => SignInMethodsRequest._();
  @$core.pragma('dart2js:noInline')
  static SignInMethodsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SignInMethodsRequest>(
          SignInMethodsRequest.$_createMessage);
  static SignInMethodsRequest? _defaultInstance;
}

class SignInMethodsResponse extends $pb.GeneratedMessage {
  factory SignInMethodsResponse({
    $core.Iterable<$core.String>? methods,
    $core.String? googleEmail,
  }) {
    final result = SignInMethodsResponse._();
    if (methods != null) result.methods.addAll(methods);
    if (googleEmail != null) result.googleEmail = googleEmail;
    return result;
  }

  SignInMethodsResponse._();

  factory SignInMethodsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SignInMethodsResponse()..mergeFromBuffer(data, registry);
  factory SignInMethodsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SignInMethodsResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SignInMethodsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ratatosk.v1'),
      createEmptyInstance: SignInMethodsResponse.$_createMessage)
    ..pPS(1, _omitFieldNames ? '' : 'methods')
    ..aOS(2, _omitFieldNames ? '' : 'googleEmail')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SignInMethodsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SignInMethodsResponse copyWith(
          void Function(SignInMethodsResponse) updates) =>
      super.copyWith((message) => updates(message as SignInMethodsResponse))
          as SignInMethodsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SignInMethodsResponse() / SignInMethodsResponse.new instead')
  static SignInMethodsResponse create() => SignInMethodsResponse._();
  static $pb.GeneratedMessage $_createMessage() => SignInMethodsResponse._();
  @$core.override
  SignInMethodsResponse createEmptyInstance() => SignInMethodsResponse._();
  @$core.pragma('dart2js:noInline')
  static SignInMethodsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SignInMethodsResponse>(
          SignInMethodsResponse.$_createMessage);
  static SignInMethodsResponse? _defaultInstance;

  /// "password" and/or "google".
  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get methods => $_getList(0);

  /// Set when a Google identity is linked, for display.
  @$pb.TagNumber(2)
  $core.String get googleEmail => $_getSZ(1);
  @$pb.TagNumber(2)
  set googleEmail($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasGoogleEmail() => $_has(1);
  @$pb.TagNumber(2)
  void clearGoogleEmail() => $_clearField(2);
}

/// Account creation, sign-in and profile management.
///
/// Register and Login are the only procedures that work without a bearer
/// token; everything else needs `Authorization: Bearer <token>`, which the
/// server resolves into the calling user.
class AuthServiceApi {
  final $pb.RpcClient _client;

  AuthServiceApi(this._client);

  /// Create an account and return a session token.
  $async.Future<RegisterResponse> register(
          $pb.ClientContext? ctx, RegisterRequest request) =>
      _client.invoke<RegisterResponse>(
          ctx, 'AuthService', 'Register', request, RegisterResponse());

  /// Exchange username and password for a session token.
  $async.Future<LoginResponse> login(
          $pb.ClientContext? ctx, LoginRequest request) =>
      _client.invoke<LoginResponse>(
          ctx, 'AuthService', 'Login', request, LoginResponse());

  /// Revoke the token used for this call.
  $async.Future<LogoutResponse> logout(
          $pb.ClientContext? ctx, LogoutRequest request) =>
      _client.invoke<LogoutResponse>(
          ctx, 'AuthService', 'Logout', request, LogoutResponse());

  /// The calling user, refreshed (presence, profile edits).
  $async.Future<GetMeResponse> getMe(
          $pb.ClientContext? ctx, GetMeRequest request) =>
      _client.invoke<GetMeResponse>(
          ctx, 'AuthService', 'GetMe', request, GetMeResponse());

  /// Edit display name, bio, accent color or profile picture.
  $async.Future<UpdateProfileResponse> updateProfile(
          $pb.ClientContext? ctx, UpdateProfileRequest request) =>
      _client.invoke<UpdateProfileResponse>(ctx, 'AuthService', 'UpdateProfile',
          request, UpdateProfileResponse());

  /// Rotate the password; other sessions stay valid.
  $async.Future<ChangePasswordResponse> changePassword(
          $pb.ClientContext? ctx, ChangePasswordRequest request) =>
      _client.invoke<ChangePasswordResponse>(ctx, 'AuthService',
          'ChangePassword', request, ChangePasswordResponse());

  /// Delete the calling account and everything that belongs to it.
  ///
  /// Requires the password to be repeated in the request: an action this
  /// destructive must not be reachable by anyone who merely has a live session
  /// (a shared laptop, a stolen token). It is the one irreversible thing a user
  /// can ask for, so the same check the operator's --delete-account does applies.
  $async.Future<DeleteAccountResponse> deleteAccount(
          $pb.ClientContext? ctx, DeleteAccountRequest request) =>
      _client.invoke<DeleteAccountResponse>(ctx, 'AuthService', 'DeleteAccount',
          request, DeleteAccountResponse());

  /// Turn a verified social sign-in into an account.
  ///
  /// Reached only through the server's own OAuth callback: the browser comes back
  /// with an opaque pending token, and the password (if any) is chosen here. An
  /// invitation is required, because this server is invite-only.
  $async.Future<FinishGoogleSignUpResponse> finishGoogleSignUp(
          $pb.ClientContext? ctx, FinishGoogleSignUpRequest request) =>
      _client.invoke<FinishGoogleSignUpResponse>(ctx, 'AuthService',
          'FinishGoogleSignUp', request, FinishGoogleSignUpResponse());

  /// Whether this server offers Google sign-in at all, and the client id and
  /// callback the browser needs. Public: it is shown before anybody signs in.
  $async.Future<GoogleSignInConfigResponse> googleSignInConfig(
          $pb.ClientContext? ctx, GoogleSignInConfigRequest request) =>
      _client.invoke<GoogleSignInConfigResponse>(ctx, 'AuthService',
          'GoogleSignInConfig', request, GoogleSignInConfigResponse());

  /// The sign-in methods this account has, so Settings can show them.
  $async.Future<SignInMethodsResponse> signInMethods(
          $pb.ClientContext? ctx, SignInMethodsRequest request) =>
      _client.invoke<SignInMethodsResponse>(ctx, 'AuthService', 'SignInMethods',
          request, SignInMethodsResponse());
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
