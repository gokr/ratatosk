// This is a generated file - do not edit.
//
// Generated from ratatosk/v1/auth.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

import 'package:protobuf/well_known_types/google/protobuf/timestamp.pbjson.dart'
    as $1;

import 'common.pbjson.dart' as $0;

@$core.Deprecated('Use registerRequestDescriptor instead')
const RegisterRequest$json = {
  '1': 'RegisterRequest',
  '2': [
    {'1': 'username', '3': 1, '4': 1, '5': 9, '10': 'username'},
    {'1': 'password', '3': 2, '4': 1, '5': 9, '10': 'password'},
    {'1': 'display_name', '3': 3, '4': 1, '5': 9, '10': 'displayName'},
  ],
};

/// Descriptor for `RegisterRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List registerRequestDescriptor = $convert.base64Decode(
    'Cg9SZWdpc3RlclJlcXVlc3QSGgoIdXNlcm5hbWUYASABKAlSCHVzZXJuYW1lEhoKCHBhc3N3b3'
    'JkGAIgASgJUghwYXNzd29yZBIhCgxkaXNwbGF5X25hbWUYAyABKAlSC2Rpc3BsYXlOYW1l');

@$core.Deprecated('Use registerResponseDescriptor instead')
const RegisterResponse$json = {
  '1': 'RegisterResponse',
  '2': [
    {'1': 'token', '3': 1, '4': 1, '5': 9, '10': 'token'},
    {
      '1': 'user',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.ratatosk.v1.User',
      '10': 'user'
    },
    {
      '1': 'expires_at',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'expiresAt'
    },
  ],
};

/// Descriptor for `RegisterResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List registerResponseDescriptor = $convert.base64Decode(
    'ChBSZWdpc3RlclJlc3BvbnNlEhQKBXRva2VuGAEgASgJUgV0b2tlbhIlCgR1c2VyGAIgASgLMh'
    'EucmF0YXRvc2sudjEuVXNlclIEdXNlchI5CgpleHBpcmVzX2F0GAMgASgLMhouZ29vZ2xlLnBy'
    'b3RvYnVmLlRpbWVzdGFtcFIJZXhwaXJlc0F0');

@$core.Deprecated('Use loginRequestDescriptor instead')
const LoginRequest$json = {
  '1': 'LoginRequest',
  '2': [
    {'1': 'username', '3': 1, '4': 1, '5': 9, '10': 'username'},
    {'1': 'password', '3': 2, '4': 1, '5': 9, '10': 'password'},
  ],
};

/// Descriptor for `LoginRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List loginRequestDescriptor = $convert.base64Decode(
    'CgxMb2dpblJlcXVlc3QSGgoIdXNlcm5hbWUYASABKAlSCHVzZXJuYW1lEhoKCHBhc3N3b3JkGA'
    'IgASgJUghwYXNzd29yZA==');

@$core.Deprecated('Use loginResponseDescriptor instead')
const LoginResponse$json = {
  '1': 'LoginResponse',
  '2': [
    {'1': 'token', '3': 1, '4': 1, '5': 9, '10': 'token'},
    {
      '1': 'user',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.ratatosk.v1.User',
      '10': 'user'
    },
    {
      '1': 'expires_at',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'expiresAt'
    },
  ],
};

/// Descriptor for `LoginResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List loginResponseDescriptor = $convert.base64Decode(
    'Cg1Mb2dpblJlc3BvbnNlEhQKBXRva2VuGAEgASgJUgV0b2tlbhIlCgR1c2VyGAIgASgLMhEucm'
    'F0YXRvc2sudjEuVXNlclIEdXNlchI5CgpleHBpcmVzX2F0GAMgASgLMhouZ29vZ2xlLnByb3Rv'
    'YnVmLlRpbWVzdGFtcFIJZXhwaXJlc0F0');

@$core.Deprecated('Use logoutRequestDescriptor instead')
const LogoutRequest$json = {
  '1': 'LogoutRequest',
};

/// Descriptor for `LogoutRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List logoutRequestDescriptor =
    $convert.base64Decode('Cg1Mb2dvdXRSZXF1ZXN0');

@$core.Deprecated('Use logoutResponseDescriptor instead')
const LogoutResponse$json = {
  '1': 'LogoutResponse',
};

/// Descriptor for `LogoutResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List logoutResponseDescriptor =
    $convert.base64Decode('Cg5Mb2dvdXRSZXNwb25zZQ==');

@$core.Deprecated('Use getMeRequestDescriptor instead')
const GetMeRequest$json = {
  '1': 'GetMeRequest',
};

/// Descriptor for `GetMeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getMeRequestDescriptor =
    $convert.base64Decode('CgxHZXRNZVJlcXVlc3Q=');

@$core.Deprecated('Use getMeResponseDescriptor instead')
const GetMeResponse$json = {
  '1': 'GetMeResponse',
  '2': [
    {
      '1': 'user',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.ratatosk.v1.User',
      '10': 'user'
    },
  ],
};

/// Descriptor for `GetMeResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getMeResponseDescriptor = $convert.base64Decode(
    'Cg1HZXRNZVJlc3BvbnNlEiUKBHVzZXIYASABKAsyES5yYXRhdG9zay52MS5Vc2VyUgR1c2Vy');

@$core.Deprecated('Use updateProfileRequestDescriptor instead')
const UpdateProfileRequest$json = {
  '1': 'UpdateProfileRequest',
  '2': [
    {'1': 'display_name', '3': 1, '4': 1, '5': 9, '10': 'displayName'},
    {'1': 'bio', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'bio', '17': true},
    {
      '1': 'avatar_attachment_id',
      '3': 3,
      '4': 1,
      '5': 9,
      '10': 'avatarAttachmentId'
    },
    {'1': 'accent_color', '3': 4, '4': 1, '5': 9, '10': 'accentColor'},
    {'1': 'clear_avatar', '3': 5, '4': 1, '5': 8, '10': 'clearAvatar'},
  ],
  '8': [
    {'1': '_bio'},
  ],
};

/// Descriptor for `UpdateProfileRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateProfileRequestDescriptor = $convert.base64Decode(
    'ChRVcGRhdGVQcm9maWxlUmVxdWVzdBIhCgxkaXNwbGF5X25hbWUYASABKAlSC2Rpc3BsYXlOYW'
    '1lEhUKA2JpbxgCIAEoCUgAUgNiaW+IAQESMAoUYXZhdGFyX2F0dGFjaG1lbnRfaWQYAyABKAlS'
    'EmF2YXRhckF0dGFjaG1lbnRJZBIhCgxhY2NlbnRfY29sb3IYBCABKAlSC2FjY2VudENvbG9yEi'
    'EKDGNsZWFyX2F2YXRhchgFIAEoCFILY2xlYXJBdmF0YXJCBgoEX2Jpbw==');

@$core.Deprecated('Use updateProfileResponseDescriptor instead')
const UpdateProfileResponse$json = {
  '1': 'UpdateProfileResponse',
  '2': [
    {
      '1': 'user',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.ratatosk.v1.User',
      '10': 'user'
    },
  ],
};

/// Descriptor for `UpdateProfileResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateProfileResponseDescriptor = $convert.base64Decode(
    'ChVVcGRhdGVQcm9maWxlUmVzcG9uc2USJQoEdXNlchgBIAEoCzIRLnJhdGF0b3NrLnYxLlVzZX'
    'JSBHVzZXI=');

@$core.Deprecated('Use changePasswordRequestDescriptor instead')
const ChangePasswordRequest$json = {
  '1': 'ChangePasswordRequest',
  '2': [
    {'1': 'current_password', '3': 1, '4': 1, '5': 9, '10': 'currentPassword'},
    {'1': 'new_password', '3': 2, '4': 1, '5': 9, '10': 'newPassword'},
  ],
};

/// Descriptor for `ChangePasswordRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List changePasswordRequestDescriptor = $convert.base64Decode(
    'ChVDaGFuZ2VQYXNzd29yZFJlcXVlc3QSKQoQY3VycmVudF9wYXNzd29yZBgBIAEoCVIPY3Vycm'
    'VudFBhc3N3b3JkEiEKDG5ld19wYXNzd29yZBgCIAEoCVILbmV3UGFzc3dvcmQ=');

@$core.Deprecated('Use changePasswordResponseDescriptor instead')
const ChangePasswordResponse$json = {
  '1': 'ChangePasswordResponse',
};

/// Descriptor for `ChangePasswordResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List changePasswordResponseDescriptor =
    $convert.base64Decode('ChZDaGFuZ2VQYXNzd29yZFJlc3BvbnNl');

@$core.Deprecated('Use deleteAccountRequestDescriptor instead')
const DeleteAccountRequest$json = {
  '1': 'DeleteAccountRequest',
  '2': [
    {'1': 'password', '3': 1, '4': 1, '5': 9, '10': 'password'},
  ],
};

/// Descriptor for `DeleteAccountRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteAccountRequestDescriptor =
    $convert.base64Decode(
        'ChREZWxldGVBY2NvdW50UmVxdWVzdBIaCghwYXNzd29yZBgBIAEoCVIIcGFzc3dvcmQ=');

@$core.Deprecated('Use deleteAccountResponseDescriptor instead')
const DeleteAccountResponse$json = {
  '1': 'DeleteAccountResponse',
  '2': [
    {
      '1': 'conversations_deleted',
      '3': 1,
      '4': 1,
      '5': 5,
      '10': 'conversationsDeleted'
    },
    {'1': 'messages_deleted', '3': 2, '4': 1, '5': 5, '10': 'messagesDeleted'},
    {
      '1': 'attachments_deleted',
      '3': 3,
      '4': 1,
      '5': 5,
      '10': 'attachmentsDeleted'
    },
  ],
};

/// Descriptor for `DeleteAccountResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteAccountResponseDescriptor = $convert.base64Decode(
    'ChVEZWxldGVBY2NvdW50UmVzcG9uc2USMwoVY29udmVyc2F0aW9uc19kZWxldGVkGAEgASgFUh'
    'Rjb252ZXJzYXRpb25zRGVsZXRlZBIpChBtZXNzYWdlc19kZWxldGVkGAIgASgFUg9tZXNzYWdl'
    'c0RlbGV0ZWQSLwoTYXR0YWNobWVudHNfZGVsZXRlZBgDIAEoBVISYXR0YWNobWVudHNEZWxldG'
    'Vk');

const $core.Map<$core.String, $core.dynamic> AuthServiceBase$json = {
  '1': 'AuthService',
  '2': [
    {
      '1': 'Register',
      '2': '.ratatosk.v1.RegisterRequest',
      '3': '.ratatosk.v1.RegisterResponse',
      '4': {}
    },
    {
      '1': 'Login',
      '2': '.ratatosk.v1.LoginRequest',
      '3': '.ratatosk.v1.LoginResponse',
      '4': {}
    },
    {
      '1': 'Logout',
      '2': '.ratatosk.v1.LogoutRequest',
      '3': '.ratatosk.v1.LogoutResponse',
      '4': {}
    },
    {
      '1': 'GetMe',
      '2': '.ratatosk.v1.GetMeRequest',
      '3': '.ratatosk.v1.GetMeResponse',
      '4': {}
    },
    {
      '1': 'UpdateProfile',
      '2': '.ratatosk.v1.UpdateProfileRequest',
      '3': '.ratatosk.v1.UpdateProfileResponse',
      '4': {}
    },
    {
      '1': 'ChangePassword',
      '2': '.ratatosk.v1.ChangePasswordRequest',
      '3': '.ratatosk.v1.ChangePasswordResponse',
      '4': {}
    },
    {
      '1': 'DeleteAccount',
      '2': '.ratatosk.v1.DeleteAccountRequest',
      '3': '.ratatosk.v1.DeleteAccountResponse',
      '4': {}
    },
  ],
};

@$core.Deprecated('Use authServiceDescriptor instead')
const $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
    AuthServiceBase$messageJson = {
  '.ratatosk.v1.RegisterRequest': RegisterRequest$json,
  '.ratatosk.v1.RegisterResponse': RegisterResponse$json,
  '.ratatosk.v1.User': $0.User$json,
  '.google.protobuf.Timestamp': $1.Timestamp$json,
  '.ratatosk.v1.LoginRequest': LoginRequest$json,
  '.ratatosk.v1.LoginResponse': LoginResponse$json,
  '.ratatosk.v1.LogoutRequest': LogoutRequest$json,
  '.ratatosk.v1.LogoutResponse': LogoutResponse$json,
  '.ratatosk.v1.GetMeRequest': GetMeRequest$json,
  '.ratatosk.v1.GetMeResponse': GetMeResponse$json,
  '.ratatosk.v1.UpdateProfileRequest': UpdateProfileRequest$json,
  '.ratatosk.v1.UpdateProfileResponse': UpdateProfileResponse$json,
  '.ratatosk.v1.ChangePasswordRequest': ChangePasswordRequest$json,
  '.ratatosk.v1.ChangePasswordResponse': ChangePasswordResponse$json,
  '.ratatosk.v1.DeleteAccountRequest': DeleteAccountRequest$json,
  '.ratatosk.v1.DeleteAccountResponse': DeleteAccountResponse$json,
};

/// Descriptor for `AuthService`. Decode as a `google.protobuf.ServiceDescriptorProto`.
final $typed_data.Uint8List authServiceDescriptor = $convert.base64Decode(
    'CgtBdXRoU2VydmljZRJJCghSZWdpc3RlchIcLnJhdGF0b3NrLnYxLlJlZ2lzdGVyUmVxdWVzdB'
    'odLnJhdGF0b3NrLnYxLlJlZ2lzdGVyUmVzcG9uc2UiABJACgVMb2dpbhIZLnJhdGF0b3NrLnYx'
    'LkxvZ2luUmVxdWVzdBoaLnJhdGF0b3NrLnYxLkxvZ2luUmVzcG9uc2UiABJDCgZMb2dvdXQSGi'
    '5yYXRhdG9zay52MS5Mb2dvdXRSZXF1ZXN0GhsucmF0YXRvc2sudjEuTG9nb3V0UmVzcG9uc2Ui'
    'ABJACgVHZXRNZRIZLnJhdGF0b3NrLnYxLkdldE1lUmVxdWVzdBoaLnJhdGF0b3NrLnYxLkdldE'
    '1lUmVzcG9uc2UiABJYCg1VcGRhdGVQcm9maWxlEiEucmF0YXRvc2sudjEuVXBkYXRlUHJvZmls'
    'ZVJlcXVlc3QaIi5yYXRhdG9zay52MS5VcGRhdGVQcm9maWxlUmVzcG9uc2UiABJbCg5DaGFuZ2'
    'VQYXNzd29yZBIiLnJhdGF0b3NrLnYxLkNoYW5nZVBhc3N3b3JkUmVxdWVzdBojLnJhdGF0b3Nr'
    'LnYxLkNoYW5nZVBhc3N3b3JkUmVzcG9uc2UiABJYCg1EZWxldGVBY2NvdW50EiEucmF0YXRvc2'
    'sudjEuRGVsZXRlQWNjb3VudFJlcXVlc3QaIi5yYXRhdG9zay52MS5EZWxldGVBY2NvdW50UmVz'
    'cG9uc2UiAA==');
