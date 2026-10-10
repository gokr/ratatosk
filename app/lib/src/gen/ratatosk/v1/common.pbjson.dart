// This is a generated file - do not edit.
//
// Generated from ratatosk/v1/common.proto.

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

@$core.Deprecated('Use presenceDescriptor instead')
const Presence$json = {
  '1': 'Presence',
  '2': [
    {'1': 'PRESENCE_UNSPECIFIED', '2': 0},
    {'1': 'PRESENCE_ONLINE', '2': 1},
    {'1': 'PRESENCE_AWAY', '2': 2},
    {'1': 'PRESENCE_OFFLINE', '2': 3},
  ],
};

/// Descriptor for `Presence`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List presenceDescriptor = $convert.base64Decode(
    'CghQcmVzZW5jZRIYChRQUkVTRU5DRV9VTlNQRUNJRklFRBAAEhMKD1BSRVNFTkNFX09OTElORR'
    'ABEhEKDVBSRVNFTkNFX0FXQVkQAhIUChBQUkVTRU5DRV9PRkZMSU5FEAM=');

@$core.Deprecated('Use userDescriptor instead')
const User$json = {
  '1': 'User',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'username', '3': 2, '4': 1, '5': 9, '10': 'username'},
    {'1': 'display_name', '3': 3, '4': 1, '5': 9, '10': 'displayName'},
    {'1': 'avatar_url', '3': 4, '4': 1, '5': 9, '10': 'avatarUrl'},
    {'1': 'bio', '3': 5, '4': 1, '5': 9, '10': 'bio'},
    {
      '1': 'presence',
      '3': 6,
      '4': 1,
      '5': 14,
      '6': '.ratatosk.v1.Presence',
      '10': 'presence'
    },
    {
      '1': 'last_seen',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'lastSeen'
    },
    {'1': 'accent_color', '3': 8, '4': 1, '5': 9, '10': 'accentColor'},
  ],
};

/// Descriptor for `User`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List userDescriptor = $convert.base64Decode(
    'CgRVc2VyEg4KAmlkGAEgASgJUgJpZBIaCgh1c2VybmFtZRgCIAEoCVIIdXNlcm5hbWUSIQoMZG'
    'lzcGxheV9uYW1lGAMgASgJUgtkaXNwbGF5TmFtZRIdCgphdmF0YXJfdXJsGAQgASgJUglhdmF0'
    'YXJVcmwSEAoDYmlvGAUgASgJUgNiaW8SMQoIcHJlc2VuY2UYBiABKA4yFS5yYXRhdG9zay52MS'
    '5QcmVzZW5jZVIIcHJlc2VuY2USNwoJbGFzdF9zZWVuGAcgASgLMhouZ29vZ2xlLnByb3RvYnVm'
    'LlRpbWVzdGFtcFIIbGFzdFNlZW4SIQoMYWNjZW50X2NvbG9yGAggASgJUgthY2NlbnRDb2xvcg'
    '==');

@$core.Deprecated('Use attachmentDescriptor instead')
const Attachment$json = {
  '1': 'Attachment',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'filename', '3': 2, '4': 1, '5': 9, '10': 'filename'},
    {'1': 'content_type', '3': 3, '4': 1, '5': 9, '10': 'contentType'},
    {'1': 'size', '3': 4, '4': 1, '5': 3, '10': 'size'},
    {'1': 'url', '3': 5, '4': 1, '5': 9, '10': 'url'},
    {'1': 'width', '3': 6, '4': 1, '5': 5, '10': 'width'},
    {'1': 'height', '3': 7, '4': 1, '5': 5, '10': 'height'},
    {'1': 'is_image', '3': 8, '4': 1, '5': 8, '10': 'isImage'},
  ],
};

/// Descriptor for `Attachment`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List attachmentDescriptor = $convert.base64Decode(
    'CgpBdHRhY2htZW50Eg4KAmlkGAEgASgJUgJpZBIaCghmaWxlbmFtZRgCIAEoCVIIZmlsZW5hbW'
    'USIQoMY29udGVudF90eXBlGAMgASgJUgtjb250ZW50VHlwZRISCgRzaXplGAQgASgDUgRzaXpl'
    'EhAKA3VybBgFIAEoCVIDdXJsEhQKBXdpZHRoGAYgASgFUgV3aWR0aBIWCgZoZWlnaHQYByABKA'
    'VSBmhlaWdodBIZCghpc19pbWFnZRgIIAEoCFIHaXNJbWFnZQ==');

@$core.Deprecated('Use replyPreviewDescriptor instead')
const ReplyPreview$json = {
  '1': 'ReplyPreview',
  '2': [
    {'1': 'message_id', '3': 1, '4': 1, '5': 9, '10': 'messageId'},
    {'1': 'sender_id', '3': 2, '4': 1, '5': 9, '10': 'senderId'},
    {'1': 'sender_name', '3': 3, '4': 1, '5': 9, '10': 'senderName'},
    {'1': 'text', '3': 4, '4': 1, '5': 9, '10': 'text'},
    {'1': 'deleted', '3': 5, '4': 1, '5': 8, '10': 'deleted'},
    {'1': 'has_attachment', '3': 6, '4': 1, '5': 8, '10': 'hasAttachment'},
  ],
};

/// Descriptor for `ReplyPreview`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List replyPreviewDescriptor = $convert.base64Decode(
    'CgxSZXBseVByZXZpZXcSHQoKbWVzc2FnZV9pZBgBIAEoCVIJbWVzc2FnZUlkEhsKCXNlbmRlcl'
    '9pZBgCIAEoCVIIc2VuZGVySWQSHwoLc2VuZGVyX25hbWUYAyABKAlSCnNlbmRlck5hbWUSEgoE'
    'dGV4dBgEIAEoCVIEdGV4dBIYCgdkZWxldGVkGAUgASgIUgdkZWxldGVkEiUKDmhhc19hdHRhY2'
    'htZW50GAYgASgIUg1oYXNBdHRhY2htZW50');
