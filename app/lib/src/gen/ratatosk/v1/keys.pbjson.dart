// This is a generated file - do not edit.
//
// Generated from ratatosk/v1/keys.proto.

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
    as $0;

@$core.Deprecated('Use deviceKeyDescriptor instead')
const DeviceKey$json = {
  '1': 'DeviceKey',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'user_id', '3': 2, '4': 1, '5': 9, '10': 'userId'},
    {
      '1': 'identity_public_key',
      '3': 3,
      '4': 1,
      '5': 12,
      '10': 'identityPublicKey'
    },
    {
      '1': 'signing_public_key',
      '3': 4,
      '4': 1,
      '5': 12,
      '10': 'signingPublicKey'
    },
    {'1': 'label', '3': 5, '4': 1, '5': 9, '10': 'label'},
    {'1': 'platform', '3': 6, '4': 1, '5': 9, '10': 'platform'},
    {
      '1': 'created_at',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'createdAt'
    },
    {
      '1': 'last_seen',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'lastSeen'
    },
    {'1': 'fingerprint', '3': 9, '4': 1, '5': 9, '10': 'fingerprint'},
    {'1': 'revoked', '3': 10, '4': 1, '5': 8, '10': 'revoked'},
  ],
};

/// Descriptor for `DeviceKey`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deviceKeyDescriptor = $convert.base64Decode(
    'CglEZXZpY2VLZXkSDgoCaWQYASABKAlSAmlkEhcKB3VzZXJfaWQYAiABKAlSBnVzZXJJZBIuCh'
    'NpZGVudGl0eV9wdWJsaWNfa2V5GAMgASgMUhFpZGVudGl0eVB1YmxpY0tleRIsChJzaWduaW5n'
    'X3B1YmxpY19rZXkYBCABKAxSEHNpZ25pbmdQdWJsaWNLZXkSFAoFbGFiZWwYBSABKAlSBWxhYm'
    'VsEhoKCHBsYXRmb3JtGAYgASgJUghwbGF0Zm9ybRI5CgpjcmVhdGVkX2F0GAcgASgLMhouZ29v'
    'Z2xlLnByb3RvYnVmLlRpbWVzdGFtcFIJY3JlYXRlZEF0EjcKCWxhc3Rfc2VlbhgIIAEoCzIaLm'
    'dvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCGxhc3RTZWVuEiAKC2ZpbmdlcnByaW50GAkgASgJ'
    'UgtmaW5nZXJwcmludBIYCgdyZXZva2VkGAogASgIUgdyZXZva2Vk');

@$core.Deprecated('Use keyEnvelopeDescriptor instead')
const KeyEnvelope$json = {
  '1': 'KeyEnvelope',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'conversation_id', '3': 2, '4': 1, '5': 9, '10': 'conversationId'},
    {
      '1': 'sender_device_key_id',
      '3': 3,
      '4': 1,
      '5': 9,
      '10': 'senderDeviceKeyId'
    },
    {
      '1': 'recipient_device_key_id',
      '3': 4,
      '4': 1,
      '5': 9,
      '10': 'recipientDeviceKeyId'
    },
    {'1': 'epoch', '3': 5, '4': 1, '5': 5, '10': 'epoch'},
    {'1': 'wrapped_key', '3': 6, '4': 1, '5': 12, '10': 'wrappedKey'},
    {'1': 'nonce', '3': 7, '4': 1, '5': 12, '10': 'nonce'},
    {
      '1': 'created_at',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'createdAt'
    },
  ],
};

/// Descriptor for `KeyEnvelope`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List keyEnvelopeDescriptor = $convert.base64Decode(
    'CgtLZXlFbnZlbG9wZRIOCgJpZBgBIAEoCVICaWQSJwoPY29udmVyc2F0aW9uX2lkGAIgASgJUg'
    '5jb252ZXJzYXRpb25JZBIvChRzZW5kZXJfZGV2aWNlX2tleV9pZBgDIAEoCVIRc2VuZGVyRGV2'
    'aWNlS2V5SWQSNQoXcmVjaXBpZW50X2RldmljZV9rZXlfaWQYBCABKAlSFHJlY2lwaWVudERldm'
    'ljZUtleUlkEhQKBWVwb2NoGAUgASgFUgVlcG9jaBIfCgt3cmFwcGVkX2tleRgGIAEoDFIKd3Jh'
    'cHBlZEtleRIUCgVub25jZRgHIAEoDFIFbm9uY2USOQoKY3JlYXRlZF9hdBgIIAEoCzIaLmdvb2'
    'dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCWNyZWF0ZWRBdA==');

@$core.Deprecated('Use publishDeviceKeyRequestDescriptor instead')
const PublishDeviceKeyRequest$json = {
  '1': 'PublishDeviceKeyRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {
      '1': 'identity_public_key',
      '3': 2,
      '4': 1,
      '5': 12,
      '10': 'identityPublicKey'
    },
    {
      '1': 'signing_public_key',
      '3': 3,
      '4': 1,
      '5': 12,
      '10': 'signingPublicKey'
    },
    {'1': 'label', '3': 4, '4': 1, '5': 9, '10': 'label'},
    {'1': 'platform', '3': 5, '4': 1, '5': 9, '10': 'platform'},
  ],
};

/// Descriptor for `PublishDeviceKeyRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List publishDeviceKeyRequestDescriptor = $convert.base64Decode(
    'ChdQdWJsaXNoRGV2aWNlS2V5UmVxdWVzdBIOCgJpZBgBIAEoCVICaWQSLgoTaWRlbnRpdHlfcH'
    'VibGljX2tleRgCIAEoDFIRaWRlbnRpdHlQdWJsaWNLZXkSLAoSc2lnbmluZ19wdWJsaWNfa2V5'
    'GAMgASgMUhBzaWduaW5nUHVibGljS2V5EhQKBWxhYmVsGAQgASgJUgVsYWJlbBIaCghwbGF0Zm'
    '9ybRgFIAEoCVIIcGxhdGZvcm0=');

@$core.Deprecated('Use publishDeviceKeyResponseDescriptor instead')
const PublishDeviceKeyResponse$json = {
  '1': 'PublishDeviceKeyResponse',
  '2': [
    {
      '1': 'device_key',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.ratatosk.v1.DeviceKey',
      '10': 'deviceKey'
    },
  ],
};

/// Descriptor for `PublishDeviceKeyResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List publishDeviceKeyResponseDescriptor =
    $convert.base64Decode(
        'ChhQdWJsaXNoRGV2aWNlS2V5UmVzcG9uc2USNQoKZGV2aWNlX2tleRgBIAEoCzIWLnJhdGF0b3'
        'NrLnYxLkRldmljZUtleVIJZGV2aWNlS2V5');

@$core.Deprecated('Use listDeviceKeysRequestDescriptor instead')
const ListDeviceKeysRequest$json = {
  '1': 'ListDeviceKeysRequest',
  '2': [
    {'1': 'user_ids', '3': 1, '4': 3, '5': 9, '10': 'userIds'},
    {'1': 'include_revoked', '3': 2, '4': 1, '5': 8, '10': 'includeRevoked'},
  ],
};

/// Descriptor for `ListDeviceKeysRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listDeviceKeysRequestDescriptor = $convert.base64Decode(
    'ChVMaXN0RGV2aWNlS2V5c1JlcXVlc3QSGQoIdXNlcl9pZHMYASADKAlSB3VzZXJJZHMSJwoPaW'
    '5jbHVkZV9yZXZva2VkGAIgASgIUg5pbmNsdWRlUmV2b2tlZA==');

@$core.Deprecated('Use listDeviceKeysResponseDescriptor instead')
const ListDeviceKeysResponse$json = {
  '1': 'ListDeviceKeysResponse',
  '2': [
    {
      '1': 'device_keys',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.ratatosk.v1.DeviceKey',
      '10': 'deviceKeys'
    },
  ],
};

/// Descriptor for `ListDeviceKeysResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listDeviceKeysResponseDescriptor =
    $convert.base64Decode(
        'ChZMaXN0RGV2aWNlS2V5c1Jlc3BvbnNlEjcKC2RldmljZV9rZXlzGAEgAygLMhYucmF0YXRvc2'
        'sudjEuRGV2aWNlS2V5UgpkZXZpY2VLZXlz');

@$core.Deprecated('Use revokeDeviceKeyRequestDescriptor instead')
const RevokeDeviceKeyRequest$json = {
  '1': 'RevokeDeviceKeyRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `RevokeDeviceKeyRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List revokeDeviceKeyRequestDescriptor = $convert
    .base64Decode('ChZSZXZva2VEZXZpY2VLZXlSZXF1ZXN0Eg4KAmlkGAEgASgJUgJpZA==');

@$core.Deprecated('Use revokeDeviceKeyResponseDescriptor instead')
const RevokeDeviceKeyResponse$json = {
  '1': 'RevokeDeviceKeyResponse',
};

/// Descriptor for `RevokeDeviceKeyResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List revokeDeviceKeyResponseDescriptor =
    $convert.base64Decode('ChdSZXZva2VEZXZpY2VLZXlSZXNwb25zZQ==');

@$core.Deprecated('Use putKeyEnvelopeRequestDescriptor instead')
const PutKeyEnvelopeRequest$json = {
  '1': 'PutKeyEnvelopeRequest',
  '2': [
    {'1': 'conversation_id', '3': 1, '4': 1, '5': 9, '10': 'conversationId'},
    {
      '1': 'sender_device_key_id',
      '3': 2,
      '4': 1,
      '5': 9,
      '10': 'senderDeviceKeyId'
    },
    {
      '1': 'recipient_device_key_id',
      '3': 3,
      '4': 1,
      '5': 9,
      '10': 'recipientDeviceKeyId'
    },
    {'1': 'epoch', '3': 4, '4': 1, '5': 5, '10': 'epoch'},
    {'1': 'wrapped_key', '3': 5, '4': 1, '5': 12, '10': 'wrappedKey'},
    {'1': 'nonce', '3': 6, '4': 1, '5': 12, '10': 'nonce'},
  ],
};

/// Descriptor for `PutKeyEnvelopeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List putKeyEnvelopeRequestDescriptor = $convert.base64Decode(
    'ChVQdXRLZXlFbnZlbG9wZVJlcXVlc3QSJwoPY29udmVyc2F0aW9uX2lkGAEgASgJUg5jb252ZX'
    'JzYXRpb25JZBIvChRzZW5kZXJfZGV2aWNlX2tleV9pZBgCIAEoCVIRc2VuZGVyRGV2aWNlS2V5'
    'SWQSNQoXcmVjaXBpZW50X2RldmljZV9rZXlfaWQYAyABKAlSFHJlY2lwaWVudERldmljZUtleU'
    'lkEhQKBWVwb2NoGAQgASgFUgVlcG9jaBIfCgt3cmFwcGVkX2tleRgFIAEoDFIKd3JhcHBlZEtl'
    'eRIUCgVub25jZRgGIAEoDFIFbm9uY2U=');

@$core.Deprecated('Use putKeyEnvelopeResponseDescriptor instead')
const PutKeyEnvelopeResponse$json = {
  '1': 'PutKeyEnvelopeResponse',
  '2': [
    {
      '1': 'envelope',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.ratatosk.v1.KeyEnvelope',
      '10': 'envelope'
    },
  ],
};

/// Descriptor for `PutKeyEnvelopeResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List putKeyEnvelopeResponseDescriptor =
    $convert.base64Decode(
        'ChZQdXRLZXlFbnZlbG9wZVJlc3BvbnNlEjQKCGVudmVsb3BlGAEgASgLMhgucmF0YXRvc2sudj'
        'EuS2V5RW52ZWxvcGVSCGVudmVsb3Bl');

@$core.Deprecated('Use listKeyEnvelopesRequestDescriptor instead')
const ListKeyEnvelopesRequest$json = {
  '1': 'ListKeyEnvelopesRequest',
  '2': [
    {'1': 'conversation_id', '3': 1, '4': 1, '5': 9, '10': 'conversationId'},
    {
      '1': 'since',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'since'
    },
  ],
};

/// Descriptor for `ListKeyEnvelopesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listKeyEnvelopesRequestDescriptor = $convert.base64Decode(
    'ChdMaXN0S2V5RW52ZWxvcGVzUmVxdWVzdBInCg9jb252ZXJzYXRpb25faWQYASABKAlSDmNvbn'
    'ZlcnNhdGlvbklkEjAKBXNpbmNlGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIF'
    'c2luY2U=');

@$core.Deprecated('Use listKeyEnvelopesResponseDescriptor instead')
const ListKeyEnvelopesResponse$json = {
  '1': 'ListKeyEnvelopesResponse',
  '2': [
    {
      '1': 'envelopes',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.ratatosk.v1.KeyEnvelope',
      '10': 'envelopes'
    },
  ],
};

/// Descriptor for `ListKeyEnvelopesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listKeyEnvelopesResponseDescriptor =
    $convert.base64Decode(
        'ChhMaXN0S2V5RW52ZWxvcGVzUmVzcG9uc2USNgoJZW52ZWxvcGVzGAEgAygLMhgucmF0YXRvc2'
        'sudjEuS2V5RW52ZWxvcGVSCWVudmVsb3Blcw==');

@$core.Deprecated('Use keyBackupDescriptor instead')
const KeyBackup$json = {
  '1': 'KeyBackup',
  '2': [
    {'1': 'salt', '3': 1, '4': 1, '5': 12, '10': 'salt'},
    {'1': 'nonce', '3': 2, '4': 1, '5': 12, '10': 'nonce'},
    {'1': 'blob', '3': 3, '4': 1, '5': 12, '10': 'blob'},
    {'1': 'kdf', '3': 4, '4': 1, '5': 9, '10': 'kdf'},
    {'1': 'memory_kib', '3': 5, '4': 1, '5': 5, '10': 'memoryKib'},
    {'1': 'iterations', '3': 6, '4': 1, '5': 5, '10': 'iterations'},
    {'1': 'parallelism', '3': 7, '4': 1, '5': 5, '10': 'parallelism'},
    {'1': 'version', '3': 8, '4': 1, '5': 9, '10': 'version'},
    {
      '1': 'updated_at',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'updatedAt'
    },
  ],
};

/// Descriptor for `KeyBackup`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List keyBackupDescriptor = $convert.base64Decode(
    'CglLZXlCYWNrdXASEgoEc2FsdBgBIAEoDFIEc2FsdBIUCgVub25jZRgCIAEoDFIFbm9uY2USEg'
    'oEYmxvYhgDIAEoDFIEYmxvYhIQCgNrZGYYBCABKAlSA2tkZhIdCgptZW1vcnlfa2liGAUgASgF'
    'UgltZW1vcnlLaWISHgoKaXRlcmF0aW9ucxgGIAEoBVIKaXRlcmF0aW9ucxIgCgtwYXJhbGxlbG'
    'lzbRgHIAEoBVILcGFyYWxsZWxpc20SGAoHdmVyc2lvbhgIIAEoCVIHdmVyc2lvbhI5Cgp1cGRh'
    'dGVkX2F0GAkgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIJdXBkYXRlZEF0');

@$core.Deprecated('Use putKeyBackupRequestDescriptor instead')
const PutKeyBackupRequest$json = {
  '1': 'PutKeyBackupRequest',
  '2': [
    {
      '1': 'backup',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.ratatosk.v1.KeyBackup',
      '10': 'backup'
    },
  ],
};

/// Descriptor for `PutKeyBackupRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List putKeyBackupRequestDescriptor = $convert.base64Decode(
    'ChNQdXRLZXlCYWNrdXBSZXF1ZXN0Ei4KBmJhY2t1cBgBIAEoCzIWLnJhdGF0b3NrLnYxLktleU'
    'JhY2t1cFIGYmFja3Vw');

@$core.Deprecated('Use putKeyBackupResponseDescriptor instead')
const PutKeyBackupResponse$json = {
  '1': 'PutKeyBackupResponse',
  '2': [
    {
      '1': 'backup',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.ratatosk.v1.KeyBackup',
      '10': 'backup'
    },
  ],
};

/// Descriptor for `PutKeyBackupResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List putKeyBackupResponseDescriptor = $convert.base64Decode(
    'ChRQdXRLZXlCYWNrdXBSZXNwb25zZRIuCgZiYWNrdXAYASABKAsyFi5yYXRhdG9zay52MS5LZX'
    'lCYWNrdXBSBmJhY2t1cA==');

@$core.Deprecated('Use getKeyBackupRequestDescriptor instead')
const GetKeyBackupRequest$json = {
  '1': 'GetKeyBackupRequest',
};

/// Descriptor for `GetKeyBackupRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getKeyBackupRequestDescriptor =
    $convert.base64Decode('ChNHZXRLZXlCYWNrdXBSZXF1ZXN0');

@$core.Deprecated('Use getKeyBackupResponseDescriptor instead')
const GetKeyBackupResponse$json = {
  '1': 'GetKeyBackupResponse',
  '2': [
    {
      '1': 'backup',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.ratatosk.v1.KeyBackup',
      '10': 'backup'
    },
  ],
};

/// Descriptor for `GetKeyBackupResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getKeyBackupResponseDescriptor = $convert.base64Decode(
    'ChRHZXRLZXlCYWNrdXBSZXNwb25zZRIuCgZiYWNrdXAYASABKAsyFi5yYXRhdG9zay52MS5LZX'
    'lCYWNrdXBSBmJhY2t1cA==');

@$core.Deprecated('Use deleteKeyBackupRequestDescriptor instead')
const DeleteKeyBackupRequest$json = {
  '1': 'DeleteKeyBackupRequest',
};

/// Descriptor for `DeleteKeyBackupRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteKeyBackupRequestDescriptor =
    $convert.base64Decode('ChZEZWxldGVLZXlCYWNrdXBSZXF1ZXN0');

@$core.Deprecated('Use deleteKeyBackupResponseDescriptor instead')
const DeleteKeyBackupResponse$json = {
  '1': 'DeleteKeyBackupResponse',
};

/// Descriptor for `DeleteKeyBackupResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteKeyBackupResponseDescriptor =
    $convert.base64Decode('ChdEZWxldGVLZXlCYWNrdXBSZXNwb25zZQ==');

const $core.Map<$core.String, $core.dynamic> KeyServiceBase$json = {
  '1': 'KeyService',
  '2': [
    {
      '1': 'PublishDeviceKey',
      '2': '.ratatosk.v1.PublishDeviceKeyRequest',
      '3': '.ratatosk.v1.PublishDeviceKeyResponse',
      '4': {}
    },
    {
      '1': 'ListDeviceKeys',
      '2': '.ratatosk.v1.ListDeviceKeysRequest',
      '3': '.ratatosk.v1.ListDeviceKeysResponse',
      '4': {}
    },
    {
      '1': 'RevokeDeviceKey',
      '2': '.ratatosk.v1.RevokeDeviceKeyRequest',
      '3': '.ratatosk.v1.RevokeDeviceKeyResponse',
      '4': {}
    },
    {
      '1': 'PutKeyEnvelope',
      '2': '.ratatosk.v1.PutKeyEnvelopeRequest',
      '3': '.ratatosk.v1.PutKeyEnvelopeResponse',
      '4': {}
    },
    {
      '1': 'ListKeyEnvelopes',
      '2': '.ratatosk.v1.ListKeyEnvelopesRequest',
      '3': '.ratatosk.v1.ListKeyEnvelopesResponse',
      '4': {}
    },
    {
      '1': 'PutKeyBackup',
      '2': '.ratatosk.v1.PutKeyBackupRequest',
      '3': '.ratatosk.v1.PutKeyBackupResponse',
      '4': {}
    },
    {
      '1': 'GetKeyBackup',
      '2': '.ratatosk.v1.GetKeyBackupRequest',
      '3': '.ratatosk.v1.GetKeyBackupResponse',
      '4': {}
    },
    {
      '1': 'DeleteKeyBackup',
      '2': '.ratatosk.v1.DeleteKeyBackupRequest',
      '3': '.ratatosk.v1.DeleteKeyBackupResponse',
      '4': {}
    },
  ],
};

@$core.Deprecated('Use keyServiceDescriptor instead')
const $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
    KeyServiceBase$messageJson = {
  '.ratatosk.v1.PublishDeviceKeyRequest': PublishDeviceKeyRequest$json,
  '.ratatosk.v1.PublishDeviceKeyResponse': PublishDeviceKeyResponse$json,
  '.ratatosk.v1.DeviceKey': DeviceKey$json,
  '.google.protobuf.Timestamp': $0.Timestamp$json,
  '.ratatosk.v1.ListDeviceKeysRequest': ListDeviceKeysRequest$json,
  '.ratatosk.v1.ListDeviceKeysResponse': ListDeviceKeysResponse$json,
  '.ratatosk.v1.RevokeDeviceKeyRequest': RevokeDeviceKeyRequest$json,
  '.ratatosk.v1.RevokeDeviceKeyResponse': RevokeDeviceKeyResponse$json,
  '.ratatosk.v1.PutKeyEnvelopeRequest': PutKeyEnvelopeRequest$json,
  '.ratatosk.v1.PutKeyEnvelopeResponse': PutKeyEnvelopeResponse$json,
  '.ratatosk.v1.KeyEnvelope': KeyEnvelope$json,
  '.ratatosk.v1.ListKeyEnvelopesRequest': ListKeyEnvelopesRequest$json,
  '.ratatosk.v1.ListKeyEnvelopesResponse': ListKeyEnvelopesResponse$json,
  '.ratatosk.v1.PutKeyBackupRequest': PutKeyBackupRequest$json,
  '.ratatosk.v1.KeyBackup': KeyBackup$json,
  '.ratatosk.v1.PutKeyBackupResponse': PutKeyBackupResponse$json,
  '.ratatosk.v1.GetKeyBackupRequest': GetKeyBackupRequest$json,
  '.ratatosk.v1.GetKeyBackupResponse': GetKeyBackupResponse$json,
  '.ratatosk.v1.DeleteKeyBackupRequest': DeleteKeyBackupRequest$json,
  '.ratatosk.v1.DeleteKeyBackupResponse': DeleteKeyBackupResponse$json,
};

/// Descriptor for `KeyService`. Decode as a `google.protobuf.ServiceDescriptorProto`.
final $typed_data.Uint8List keyServiceDescriptor = $convert.base64Decode(
    'CgpLZXlTZXJ2aWNlEmEKEFB1Ymxpc2hEZXZpY2VLZXkSJC5yYXRhdG9zay52MS5QdWJsaXNoRG'
    'V2aWNlS2V5UmVxdWVzdBolLnJhdGF0b3NrLnYxLlB1Ymxpc2hEZXZpY2VLZXlSZXNwb25zZSIA'
    'ElsKDkxpc3REZXZpY2VLZXlzEiIucmF0YXRvc2sudjEuTGlzdERldmljZUtleXNSZXF1ZXN0Gi'
    'MucmF0YXRvc2sudjEuTGlzdERldmljZUtleXNSZXNwb25zZSIAEl4KD1Jldm9rZURldmljZUtl'
    'eRIjLnJhdGF0b3NrLnYxLlJldm9rZURldmljZUtleVJlcXVlc3QaJC5yYXRhdG9zay52MS5SZX'
    'Zva2VEZXZpY2VLZXlSZXNwb25zZSIAElsKDlB1dEtleUVudmVsb3BlEiIucmF0YXRvc2sudjEu'
    'UHV0S2V5RW52ZWxvcGVSZXF1ZXN0GiMucmF0YXRvc2sudjEuUHV0S2V5RW52ZWxvcGVSZXNwb2'
    '5zZSIAEmEKEExpc3RLZXlFbnZlbG9wZXMSJC5yYXRhdG9zay52MS5MaXN0S2V5RW52ZWxvcGVz'
    'UmVxdWVzdBolLnJhdGF0b3NrLnYxLkxpc3RLZXlFbnZlbG9wZXNSZXNwb25zZSIAElUKDFB1dE'
    'tleUJhY2t1cBIgLnJhdGF0b3NrLnYxLlB1dEtleUJhY2t1cFJlcXVlc3QaIS5yYXRhdG9zay52'
    'MS5QdXRLZXlCYWNrdXBSZXNwb25zZSIAElUKDEdldEtleUJhY2t1cBIgLnJhdGF0b3NrLnYxLk'
    'dldEtleUJhY2t1cFJlcXVlc3QaIS5yYXRhdG9zay52MS5HZXRLZXlCYWNrdXBSZXNwb25zZSIA'
    'El4KD0RlbGV0ZUtleUJhY2t1cBIjLnJhdGF0b3NrLnYxLkRlbGV0ZUtleUJhY2t1cFJlcXVlc3'
    'QaJC5yYXRhdG9zay52MS5EZWxldGVLZXlCYWNrdXBSZXNwb25zZSIA');
