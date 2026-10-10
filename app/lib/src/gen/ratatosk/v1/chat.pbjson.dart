// This is a generated file - do not edit.
//
// Generated from ratatosk/v1/chat.proto.

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

@$core.Deprecated('Use messageKindDescriptor instead')
const MessageKind$json = {
  '1': 'MessageKind',
  '2': [
    {'1': 'MESSAGE_KIND_UNSPECIFIED', '2': 0},
    {'1': 'MESSAGE_KIND_TEXT', '2': 1},
    {'1': 'MESSAGE_KIND_SYSTEM', '2': 2},
  ],
};

/// Descriptor for `MessageKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List messageKindDescriptor = $convert.base64Decode(
    'CgtNZXNzYWdlS2luZBIcChhNRVNTQUdFX0tJTkRfVU5TUEVDSUZJRUQQABIVChFNRVNTQUdFX0'
    'tJTkRfVEVYVBABEhcKE01FU1NBR0VfS0lORF9TWVNURU0QAg==');

@$core.Deprecated('Use reactionDescriptor instead')
const Reaction$json = {
  '1': 'Reaction',
  '2': [
    {'1': 'emoji', '3': 1, '4': 1, '5': 9, '10': 'emoji'},
    {'1': 'user_ids', '3': 2, '4': 3, '5': 9, '10': 'userIds'},
  ],
};

/// Descriptor for `Reaction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reactionDescriptor = $convert.base64Decode(
    'CghSZWFjdGlvbhIUCgVlbW9qaRgBIAEoCVIFZW1vamkSGQoIdXNlcl9pZHMYAiADKAlSB3VzZX'
    'JJZHM=');

@$core.Deprecated('Use messageDescriptor instead')
const Message$json = {
  '1': 'Message',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'conversation_id', '3': 2, '4': 1, '5': 9, '10': 'conversationId'},
    {'1': 'sender_id', '3': 3, '4': 1, '5': 9, '10': 'senderId'},
    {'1': 'text', '3': 4, '4': 1, '5': 9, '10': 'text'},
    {
      '1': 'attachments',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.ratatosk.v1.Attachment',
      '10': 'attachments'
    },
    {
      '1': 'created_at',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'createdAt'
    },
    {
      '1': 'edited_at',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'editedAt'
    },
    {'1': 'deleted', '3': 8, '4': 1, '5': 8, '10': 'deleted'},
    {
      '1': 'reactions',
      '3': 9,
      '4': 3,
      '5': 11,
      '6': '.ratatosk.v1.Reaction',
      '10': 'reactions'
    },
    {
      '1': 'client_message_id',
      '3': 10,
      '4': 1,
      '5': 9,
      '10': 'clientMessageId'
    },
    {
      '1': 'kind',
      '3': 11,
      '4': 1,
      '5': 14,
      '6': '.ratatosk.v1.MessageKind',
      '10': 'kind'
    },
    {'1': 'seq', '3': 12, '4': 1, '5': 3, '10': 'seq'},
    {
      '1': 'reply_to',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.ratatosk.v1.ReplyPreview',
      '10': 'replyTo'
    },
    {'1': 'reply_to_id', '3': 14, '4': 1, '5': 9, '10': 'replyToId'},
    {'1': 'ciphertext', '3': 15, '4': 1, '5': 12, '10': 'ciphertext'},
    {'1': 'nonce', '3': 16, '4': 1, '5': 12, '10': 'nonce'},
    {
      '1': 'sender_device_key_id',
      '3': 17,
      '4': 1,
      '5': 9,
      '10': 'senderDeviceKeyId'
    },
    {'1': 'key_epoch', '3': 18, '4': 1, '5': 5, '10': 'keyEpoch'},
    {'1': 'encrypted', '3': 19, '4': 1, '5': 8, '10': 'encrypted'},
    {'1': 'crypto_version', '3': 20, '4': 1, '5': 9, '10': 'cryptoVersion'},
  ],
};

/// Descriptor for `Message`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List messageDescriptor = $convert.base64Decode(
    'CgdNZXNzYWdlEg4KAmlkGAEgASgJUgJpZBInCg9jb252ZXJzYXRpb25faWQYAiABKAlSDmNvbn'
    'ZlcnNhdGlvbklkEhsKCXNlbmRlcl9pZBgDIAEoCVIIc2VuZGVySWQSEgoEdGV4dBgEIAEoCVIE'
    'dGV4dBI5CgthdHRhY2htZW50cxgFIAMoCzIXLnJhdGF0b3NrLnYxLkF0dGFjaG1lbnRSC2F0dG'
    'FjaG1lbnRzEjkKCmNyZWF0ZWRfYXQYBiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1w'
    'UgljcmVhdGVkQXQSNwoJZWRpdGVkX2F0GAcgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdG'
    'FtcFIIZWRpdGVkQXQSGAoHZGVsZXRlZBgIIAEoCFIHZGVsZXRlZBIzCglyZWFjdGlvbnMYCSAD'
    'KAsyFS5yYXRhdG9zay52MS5SZWFjdGlvblIJcmVhY3Rpb25zEioKEWNsaWVudF9tZXNzYWdlX2'
    'lkGAogASgJUg9jbGllbnRNZXNzYWdlSWQSLAoEa2luZBgLIAEoDjIYLnJhdGF0b3NrLnYxLk1l'
    'c3NhZ2VLaW5kUgRraW5kEhAKA3NlcRgMIAEoA1IDc2VxEjQKCHJlcGx5X3RvGA0gASgLMhkucm'
    'F0YXRvc2sudjEuUmVwbHlQcmV2aWV3UgdyZXBseVRvEh4KC3JlcGx5X3RvX2lkGA4gASgJUgly'
    'ZXBseVRvSWQSHgoKY2lwaGVydGV4dBgPIAEoDFIKY2lwaGVydGV4dBIUCgVub25jZRgQIAEoDF'
    'IFbm9uY2USLwoUc2VuZGVyX2RldmljZV9rZXlfaWQYESABKAlSEXNlbmRlckRldmljZUtleUlk'
    'EhsKCWtleV9lcG9jaBgSIAEoBVIIa2V5RXBvY2gSHAoJZW5jcnlwdGVkGBMgASgIUgllbmNyeX'
    'B0ZWQSJQoOY3J5cHRvX3ZlcnNpb24YFCABKAlSDWNyeXB0b1ZlcnNpb24=');

@$core.Deprecated('Use memberDescriptor instead')
const Member$json = {
  '1': 'Member',
  '2': [
    {
      '1': 'user',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.ratatosk.v1.User',
      '10': 'user'
    },
    {'1': 'role', '3': 2, '4': 1, '5': 9, '10': 'role'},
    {
      '1': 'joined_at',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'joinedAt'
    },
    {'1': 'last_read_seq', '3': 4, '4': 1, '5': 3, '10': 'lastReadSeq'},
    {
      '1': 'last_read_at',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'lastReadAt'
    },
    {'1': 'muted', '3': 6, '4': 1, '5': 8, '10': 'muted'},
    {'1': 'pinned', '3': 7, '4': 1, '5': 8, '10': 'pinned'},
  ],
};

/// Descriptor for `Member`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List memberDescriptor = $convert.base64Decode(
    'CgZNZW1iZXISJQoEdXNlchgBIAEoCzIRLnJhdGF0b3NrLnYxLlVzZXJSBHVzZXISEgoEcm9sZR'
    'gCIAEoCVIEcm9sZRI3Cglqb2luZWRfYXQYAyABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0'
    'YW1wUghqb2luZWRBdBIiCg1sYXN0X3JlYWRfc2VxGAQgASgDUgtsYXN0UmVhZFNlcRI8CgxsYX'
    'N0X3JlYWRfYXQYBSABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgpsYXN0UmVhZEF0'
    'EhQKBW11dGVkGAYgASgIUgVtdXRlZBIWCgZwaW5uZWQYByABKAhSBnBpbm5lZA==');

@$core.Deprecated('Use conversationDescriptor instead')
const Conversation$json = {
  '1': 'Conversation',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'kind', '3': 2, '4': 1, '5': 9, '10': 'kind'},
    {'1': 'title', '3': 3, '4': 1, '5': 9, '10': 'title'},
    {'1': 'avatar_url', '3': 4, '4': 1, '5': 9, '10': 'avatarUrl'},
    {
      '1': 'members',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.ratatosk.v1.Member',
      '10': 'members'
    },
    {
      '1': 'last_message',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.ratatosk.v1.Message',
      '10': 'lastMessage'
    },
    {'1': 'unread_count', '3': 7, '4': 1, '5': 5, '10': 'unreadCount'},
    {
      '1': 'created_at',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'createdAt'
    },
    {
      '1': 'updated_at',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'updatedAt'
    },
    {'1': 'created_by', '3': 10, '4': 1, '5': 9, '10': 'createdBy'},
    {'1': 'last_seq', '3': 11, '4': 1, '5': 3, '10': 'lastSeq'},
    {'1': 'muted', '3': 12, '4': 1, '5': 8, '10': 'muted'},
    {'1': 'pinned', '3': 13, '4': 1, '5': 8, '10': 'pinned'},
    {'1': 'accent_color', '3': 14, '4': 1, '5': 9, '10': 'accentColor'},
    {
      '1': 'peer',
      '3': 15,
      '4': 1,
      '5': 11,
      '6': '.ratatosk.v1.User',
      '10': 'peer'
    },
  ],
};

/// Descriptor for `Conversation`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List conversationDescriptor = $convert.base64Decode(
    'CgxDb252ZXJzYXRpb24SDgoCaWQYASABKAlSAmlkEhIKBGtpbmQYAiABKAlSBGtpbmQSFAoFdG'
    'l0bGUYAyABKAlSBXRpdGxlEh0KCmF2YXRhcl91cmwYBCABKAlSCWF2YXRhclVybBItCgdtZW1i'
    'ZXJzGAUgAygLMhMucmF0YXRvc2sudjEuTWVtYmVyUgdtZW1iZXJzEjcKDGxhc3RfbWVzc2FnZR'
    'gGIAEoCzIULnJhdGF0b3NrLnYxLk1lc3NhZ2VSC2xhc3RNZXNzYWdlEiEKDHVucmVhZF9jb3Vu'
    'dBgHIAEoBVILdW5yZWFkQ291bnQSOQoKY3JlYXRlZF9hdBgIIAEoCzIaLmdvb2dsZS5wcm90b2'
    'J1Zi5UaW1lc3RhbXBSCWNyZWF0ZWRBdBI5Cgp1cGRhdGVkX2F0GAkgASgLMhouZ29vZ2xlLnBy'
    'b3RvYnVmLlRpbWVzdGFtcFIJdXBkYXRlZEF0Eh0KCmNyZWF0ZWRfYnkYCiABKAlSCWNyZWF0ZW'
    'RCeRIZCghsYXN0X3NlcRgLIAEoA1IHbGFzdFNlcRIUCgVtdXRlZBgMIAEoCFIFbXV0ZWQSFgoG'
    'cGlubmVkGA0gASgIUgZwaW5uZWQSIQoMYWNjZW50X2NvbG9yGA4gASgJUgthY2NlbnRDb2xvch'
    'IlCgRwZWVyGA8gASgLMhEucmF0YXRvc2sudjEuVXNlclIEcGVlcg==');

@$core.Deprecated('Use listConversationsRequestDescriptor instead')
const ListConversationsRequest$json = {
  '1': 'ListConversationsRequest',
};

/// Descriptor for `ListConversationsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listConversationsRequestDescriptor =
    $convert.base64Decode('ChhMaXN0Q29udmVyc2F0aW9uc1JlcXVlc3Q=');

@$core.Deprecated('Use listConversationsResponseDescriptor instead')
const ListConversationsResponse$json = {
  '1': 'ListConversationsResponse',
  '2': [
    {
      '1': 'conversations',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.ratatosk.v1.Conversation',
      '10': 'conversations'
    },
  ],
};

/// Descriptor for `ListConversationsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listConversationsResponseDescriptor =
    $convert.base64Decode(
        'ChlMaXN0Q29udmVyc2F0aW9uc1Jlc3BvbnNlEj8KDWNvbnZlcnNhdGlvbnMYASADKAsyGS5yYX'
        'RhdG9zay52MS5Db252ZXJzYXRpb25SDWNvbnZlcnNhdGlvbnM=');

@$core.Deprecated('Use getConversationRequestDescriptor instead')
const GetConversationRequest$json = {
  '1': 'GetConversationRequest',
  '2': [
    {'1': 'conversation_id', '3': 1, '4': 1, '5': 9, '10': 'conversationId'},
  ],
};

/// Descriptor for `GetConversationRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getConversationRequestDescriptor =
    $convert.base64Decode(
        'ChZHZXRDb252ZXJzYXRpb25SZXF1ZXN0EicKD2NvbnZlcnNhdGlvbl9pZBgBIAEoCVIOY29udm'
        'Vyc2F0aW9uSWQ=');

@$core.Deprecated('Use getConversationResponseDescriptor instead')
const GetConversationResponse$json = {
  '1': 'GetConversationResponse',
  '2': [
    {
      '1': 'conversation',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.ratatosk.v1.Conversation',
      '10': 'conversation'
    },
  ],
};

/// Descriptor for `GetConversationResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getConversationResponseDescriptor =
    $convert.base64Decode(
        'ChdHZXRDb252ZXJzYXRpb25SZXNwb25zZRI9Cgxjb252ZXJzYXRpb24YASABKAsyGS5yYXRhdG'
        '9zay52MS5Db252ZXJzYXRpb25SDGNvbnZlcnNhdGlvbg==');

@$core.Deprecated('Use createDirectConversationRequestDescriptor instead')
const CreateDirectConversationRequest$json = {
  '1': 'CreateDirectConversationRequest',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 9, '10': 'userId'},
    {'1': 'username', '3': 2, '4': 1, '5': 9, '10': 'username'},
  ],
};

/// Descriptor for `CreateDirectConversationRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createDirectConversationRequestDescriptor =
    $convert.base64Decode(
        'Ch9DcmVhdGVEaXJlY3RDb252ZXJzYXRpb25SZXF1ZXN0EhcKB3VzZXJfaWQYASABKAlSBnVzZX'
        'JJZBIaCgh1c2VybmFtZRgCIAEoCVIIdXNlcm5hbWU=');

@$core.Deprecated('Use createDirectConversationResponseDescriptor instead')
const CreateDirectConversationResponse$json = {
  '1': 'CreateDirectConversationResponse',
  '2': [
    {
      '1': 'conversation',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.ratatosk.v1.Conversation',
      '10': 'conversation'
    },
    {'1': 'created', '3': 2, '4': 1, '5': 8, '10': 'created'},
  ],
};

/// Descriptor for `CreateDirectConversationResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createDirectConversationResponseDescriptor =
    $convert.base64Decode(
        'CiBDcmVhdGVEaXJlY3RDb252ZXJzYXRpb25SZXNwb25zZRI9Cgxjb252ZXJzYXRpb24YASABKA'
        'syGS5yYXRhdG9zay52MS5Db252ZXJzYXRpb25SDGNvbnZlcnNhdGlvbhIYCgdjcmVhdGVkGAIg'
        'ASgIUgdjcmVhdGVk');

@$core.Deprecated('Use createGroupConversationRequestDescriptor instead')
const CreateGroupConversationRequest$json = {
  '1': 'CreateGroupConversationRequest',
  '2': [
    {'1': 'title', '3': 1, '4': 1, '5': 9, '10': 'title'},
    {'1': 'usernames', '3': 2, '4': 3, '5': 9, '10': 'usernames'},
    {'1': 'user_ids', '3': 3, '4': 3, '5': 9, '10': 'userIds'},
  ],
};

/// Descriptor for `CreateGroupConversationRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createGroupConversationRequestDescriptor =
    $convert.base64Decode(
        'Ch5DcmVhdGVHcm91cENvbnZlcnNhdGlvblJlcXVlc3QSFAoFdGl0bGUYASABKAlSBXRpdGxlEh'
        'wKCXVzZXJuYW1lcxgCIAMoCVIJdXNlcm5hbWVzEhkKCHVzZXJfaWRzGAMgAygJUgd1c2VySWRz');

@$core.Deprecated('Use createGroupConversationResponseDescriptor instead')
const CreateGroupConversationResponse$json = {
  '1': 'CreateGroupConversationResponse',
  '2': [
    {
      '1': 'conversation',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.ratatosk.v1.Conversation',
      '10': 'conversation'
    },
  ],
};

/// Descriptor for `CreateGroupConversationResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createGroupConversationResponseDescriptor =
    $convert.base64Decode(
        'Ch9DcmVhdGVHcm91cENvbnZlcnNhdGlvblJlc3BvbnNlEj0KDGNvbnZlcnNhdGlvbhgBIAEoCz'
        'IZLnJhdGF0b3NrLnYxLkNvbnZlcnNhdGlvblIMY29udmVyc2F0aW9u');

@$core.Deprecated('Use updateConversationRequestDescriptor instead')
const UpdateConversationRequest$json = {
  '1': 'UpdateConversationRequest',
  '2': [
    {'1': 'conversation_id', '3': 1, '4': 1, '5': 9, '10': 'conversationId'},
    {'1': 'title', '3': 2, '4': 1, '5': 9, '10': 'title'},
    {
      '1': 'avatar_attachment_id',
      '3': 3,
      '4': 1,
      '5': 9,
      '10': 'avatarAttachmentId'
    },
    {'1': 'clear_avatar', '3': 4, '4': 1, '5': 8, '10': 'clearAvatar'},
    {'1': 'muted', '3': 5, '4': 1, '5': 8, '9': 0, '10': 'muted', '17': true},
    {'1': 'pinned', '3': 6, '4': 1, '5': 8, '9': 1, '10': 'pinned', '17': true},
  ],
  '8': [
    {'1': '_muted'},
    {'1': '_pinned'},
  ],
};

/// Descriptor for `UpdateConversationRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateConversationRequestDescriptor = $convert.base64Decode(
    'ChlVcGRhdGVDb252ZXJzYXRpb25SZXF1ZXN0EicKD2NvbnZlcnNhdGlvbl9pZBgBIAEoCVIOY2'
    '9udmVyc2F0aW9uSWQSFAoFdGl0bGUYAiABKAlSBXRpdGxlEjAKFGF2YXRhcl9hdHRhY2htZW50'
    'X2lkGAMgASgJUhJhdmF0YXJBdHRhY2htZW50SWQSIQoMY2xlYXJfYXZhdGFyGAQgASgIUgtjbG'
    'VhckF2YXRhchIZCgVtdXRlZBgFIAEoCEgAUgVtdXRlZIgBARIbCgZwaW5uZWQYBiABKAhIAVIG'
    'cGlubmVkiAEBQggKBl9tdXRlZEIJCgdfcGlubmVk');

@$core.Deprecated('Use updateConversationResponseDescriptor instead')
const UpdateConversationResponse$json = {
  '1': 'UpdateConversationResponse',
  '2': [
    {
      '1': 'conversation',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.ratatosk.v1.Conversation',
      '10': 'conversation'
    },
  ],
};

/// Descriptor for `UpdateConversationResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateConversationResponseDescriptor =
    $convert.base64Decode(
        'ChpVcGRhdGVDb252ZXJzYXRpb25SZXNwb25zZRI9Cgxjb252ZXJzYXRpb24YASABKAsyGS5yYX'
        'RhdG9zay52MS5Db252ZXJzYXRpb25SDGNvbnZlcnNhdGlvbg==');

@$core.Deprecated('Use addMembersRequestDescriptor instead')
const AddMembersRequest$json = {
  '1': 'AddMembersRequest',
  '2': [
    {'1': 'conversation_id', '3': 1, '4': 1, '5': 9, '10': 'conversationId'},
    {'1': 'usernames', '3': 2, '4': 3, '5': 9, '10': 'usernames'},
    {'1': 'user_ids', '3': 3, '4': 3, '5': 9, '10': 'userIds'},
  ],
};

/// Descriptor for `AddMembersRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List addMembersRequestDescriptor = $convert.base64Decode(
    'ChFBZGRNZW1iZXJzUmVxdWVzdBInCg9jb252ZXJzYXRpb25faWQYASABKAlSDmNvbnZlcnNhdG'
    'lvbklkEhwKCXVzZXJuYW1lcxgCIAMoCVIJdXNlcm5hbWVzEhkKCHVzZXJfaWRzGAMgAygJUgd1'
    'c2VySWRz');

@$core.Deprecated('Use addMembersResponseDescriptor instead')
const AddMembersResponse$json = {
  '1': 'AddMembersResponse',
  '2': [
    {
      '1': 'conversation',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.ratatosk.v1.Conversation',
      '10': 'conversation'
    },
  ],
};

/// Descriptor for `AddMembersResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List addMembersResponseDescriptor = $convert.base64Decode(
    'ChJBZGRNZW1iZXJzUmVzcG9uc2USPQoMY29udmVyc2F0aW9uGAEgASgLMhkucmF0YXRvc2sudj'
    'EuQ29udmVyc2F0aW9uUgxjb252ZXJzYXRpb24=');

@$core.Deprecated('Use removeMemberRequestDescriptor instead')
const RemoveMemberRequest$json = {
  '1': 'RemoveMemberRequest',
  '2': [
    {'1': 'conversation_id', '3': 1, '4': 1, '5': 9, '10': 'conversationId'},
    {'1': 'user_id', '3': 2, '4': 1, '5': 9, '10': 'userId'},
  ],
};

/// Descriptor for `RemoveMemberRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List removeMemberRequestDescriptor = $convert.base64Decode(
    'ChNSZW1vdmVNZW1iZXJSZXF1ZXN0EicKD2NvbnZlcnNhdGlvbl9pZBgBIAEoCVIOY29udmVyc2'
    'F0aW9uSWQSFwoHdXNlcl9pZBgCIAEoCVIGdXNlcklk');

@$core.Deprecated('Use removeMemberResponseDescriptor instead')
const RemoveMemberResponse$json = {
  '1': 'RemoveMemberResponse',
  '2': [
    {
      '1': 'conversation',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.ratatosk.v1.Conversation',
      '10': 'conversation'
    },
  ],
};

/// Descriptor for `RemoveMemberResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List removeMemberResponseDescriptor = $convert.base64Decode(
    'ChRSZW1vdmVNZW1iZXJSZXNwb25zZRI9Cgxjb252ZXJzYXRpb24YASABKAsyGS5yYXRhdG9zay'
    '52MS5Db252ZXJzYXRpb25SDGNvbnZlcnNhdGlvbg==');

@$core.Deprecated('Use listMessagesRequestDescriptor instead')
const ListMessagesRequest$json = {
  '1': 'ListMessagesRequest',
  '2': [
    {'1': 'conversation_id', '3': 1, '4': 1, '5': 9, '10': 'conversationId'},
    {'1': 'before_seq', '3': 2, '4': 1, '5': 3, '10': 'beforeSeq'},
    {'1': 'after_seq', '3': 3, '4': 1, '5': 3, '10': 'afterSeq'},
    {'1': 'limit', '3': 4, '4': 1, '5': 5, '10': 'limit'},
  ],
};

/// Descriptor for `ListMessagesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listMessagesRequestDescriptor = $convert.base64Decode(
    'ChNMaXN0TWVzc2FnZXNSZXF1ZXN0EicKD2NvbnZlcnNhdGlvbl9pZBgBIAEoCVIOY29udmVyc2'
    'F0aW9uSWQSHQoKYmVmb3JlX3NlcRgCIAEoA1IJYmVmb3JlU2VxEhsKCWFmdGVyX3NlcRgDIAEo'
    'A1IIYWZ0ZXJTZXESFAoFbGltaXQYBCABKAVSBWxpbWl0');

@$core.Deprecated('Use listMessagesResponseDescriptor instead')
const ListMessagesResponse$json = {
  '1': 'ListMessagesResponse',
  '2': [
    {
      '1': 'messages',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.ratatosk.v1.Message',
      '10': 'messages'
    },
    {'1': 'has_more', '3': 2, '4': 1, '5': 8, '10': 'hasMore'},
  ],
};

/// Descriptor for `ListMessagesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listMessagesResponseDescriptor = $convert.base64Decode(
    'ChRMaXN0TWVzc2FnZXNSZXNwb25zZRIwCghtZXNzYWdlcxgBIAMoCzIULnJhdGF0b3NrLnYxLk'
    '1lc3NhZ2VSCG1lc3NhZ2VzEhkKCGhhc19tb3JlGAIgASgIUgdoYXNNb3Jl');

@$core.Deprecated('Use sendMessageRequestDescriptor instead')
const SendMessageRequest$json = {
  '1': 'SendMessageRequest',
  '2': [
    {'1': 'conversation_id', '3': 1, '4': 1, '5': 9, '10': 'conversationId'},
    {'1': 'text', '3': 2, '4': 1, '5': 9, '10': 'text'},
    {'1': 'attachment_ids', '3': 3, '4': 3, '5': 9, '10': 'attachmentIds'},
    {'1': 'reply_to_id', '3': 4, '4': 1, '5': 9, '10': 'replyToId'},
    {'1': 'client_message_id', '3': 5, '4': 1, '5': 9, '10': 'clientMessageId'},
    {'1': 'ciphertext', '3': 6, '4': 1, '5': 12, '10': 'ciphertext'},
    {'1': 'nonce', '3': 7, '4': 1, '5': 12, '10': 'nonce'},
    {
      '1': 'sender_device_key_id',
      '3': 8,
      '4': 1,
      '5': 9,
      '10': 'senderDeviceKeyId'
    },
    {'1': 'key_epoch', '3': 9, '4': 1, '5': 5, '10': 'keyEpoch'},
    {'1': 'crypto_version', '3': 10, '4': 1, '5': 9, '10': 'cryptoVersion'},
  ],
};

/// Descriptor for `SendMessageRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sendMessageRequestDescriptor = $convert.base64Decode(
    'ChJTZW5kTWVzc2FnZVJlcXVlc3QSJwoPY29udmVyc2F0aW9uX2lkGAEgASgJUg5jb252ZXJzYX'
    'Rpb25JZBISCgR0ZXh0GAIgASgJUgR0ZXh0EiUKDmF0dGFjaG1lbnRfaWRzGAMgAygJUg1hdHRh'
    'Y2htZW50SWRzEh4KC3JlcGx5X3RvX2lkGAQgASgJUglyZXBseVRvSWQSKgoRY2xpZW50X21lc3'
    'NhZ2VfaWQYBSABKAlSD2NsaWVudE1lc3NhZ2VJZBIeCgpjaXBoZXJ0ZXh0GAYgASgMUgpjaXBo'
    'ZXJ0ZXh0EhQKBW5vbmNlGAcgASgMUgVub25jZRIvChRzZW5kZXJfZGV2aWNlX2tleV9pZBgIIA'
    'EoCVIRc2VuZGVyRGV2aWNlS2V5SWQSGwoJa2V5X2Vwb2NoGAkgASgFUghrZXlFcG9jaBIlCg5j'
    'cnlwdG9fdmVyc2lvbhgKIAEoCVINY3J5cHRvVmVyc2lvbg==');

@$core.Deprecated('Use sendMessageResponseDescriptor instead')
const SendMessageResponse$json = {
  '1': 'SendMessageResponse',
  '2': [
    {
      '1': 'message',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.ratatosk.v1.Message',
      '10': 'message'
    },
  ],
};

/// Descriptor for `SendMessageResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sendMessageResponseDescriptor = $convert.base64Decode(
    'ChNTZW5kTWVzc2FnZVJlc3BvbnNlEi4KB21lc3NhZ2UYASABKAsyFC5yYXRhdG9zay52MS5NZX'
    'NzYWdlUgdtZXNzYWdl');

@$core.Deprecated('Use editMessageRequestDescriptor instead')
const EditMessageRequest$json = {
  '1': 'EditMessageRequest',
  '2': [
    {'1': 'message_id', '3': 1, '4': 1, '5': 9, '10': 'messageId'},
    {'1': 'text', '3': 2, '4': 1, '5': 9, '10': 'text'},
    {'1': 'ciphertext', '3': 3, '4': 1, '5': 12, '10': 'ciphertext'},
    {'1': 'nonce', '3': 4, '4': 1, '5': 12, '10': 'nonce'},
    {'1': 'crypto_version', '3': 5, '4': 1, '5': 9, '10': 'cryptoVersion'},
  ],
};

/// Descriptor for `EditMessageRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List editMessageRequestDescriptor = $convert.base64Decode(
    'ChJFZGl0TWVzc2FnZVJlcXVlc3QSHQoKbWVzc2FnZV9pZBgBIAEoCVIJbWVzc2FnZUlkEhIKBH'
    'RleHQYAiABKAlSBHRleHQSHgoKY2lwaGVydGV4dBgDIAEoDFIKY2lwaGVydGV4dBIUCgVub25j'
    'ZRgEIAEoDFIFbm9uY2USJQoOY3J5cHRvX3ZlcnNpb24YBSABKAlSDWNyeXB0b1ZlcnNpb24=');

@$core.Deprecated('Use editMessageResponseDescriptor instead')
const EditMessageResponse$json = {
  '1': 'EditMessageResponse',
  '2': [
    {
      '1': 'message',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.ratatosk.v1.Message',
      '10': 'message'
    },
  ],
};

/// Descriptor for `EditMessageResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List editMessageResponseDescriptor = $convert.base64Decode(
    'ChNFZGl0TWVzc2FnZVJlc3BvbnNlEi4KB21lc3NhZ2UYASABKAsyFC5yYXRhdG9zay52MS5NZX'
    'NzYWdlUgdtZXNzYWdl');

@$core.Deprecated('Use deleteMessageRequestDescriptor instead')
const DeleteMessageRequest$json = {
  '1': 'DeleteMessageRequest',
  '2': [
    {'1': 'message_id', '3': 1, '4': 1, '5': 9, '10': 'messageId'},
  ],
};

/// Descriptor for `DeleteMessageRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteMessageRequestDescriptor = $convert.base64Decode(
    'ChREZWxldGVNZXNzYWdlUmVxdWVzdBIdCgptZXNzYWdlX2lkGAEgASgJUgltZXNzYWdlSWQ=');

@$core.Deprecated('Use deleteMessageResponseDescriptor instead')
const DeleteMessageResponse$json = {
  '1': 'DeleteMessageResponse',
  '2': [
    {
      '1': 'message',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.ratatosk.v1.Message',
      '10': 'message'
    },
  ],
};

/// Descriptor for `DeleteMessageResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteMessageResponseDescriptor = $convert.base64Decode(
    'ChVEZWxldGVNZXNzYWdlUmVzcG9uc2USLgoHbWVzc2FnZRgBIAEoCzIULnJhdGF0b3NrLnYxLk'
    '1lc3NhZ2VSB21lc3NhZ2U=');

@$core.Deprecated('Use addReactionRequestDescriptor instead')
const AddReactionRequest$json = {
  '1': 'AddReactionRequest',
  '2': [
    {'1': 'message_id', '3': 1, '4': 1, '5': 9, '10': 'messageId'},
    {'1': 'emoji', '3': 2, '4': 1, '5': 9, '10': 'emoji'},
  ],
};

/// Descriptor for `AddReactionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List addReactionRequestDescriptor = $convert.base64Decode(
    'ChJBZGRSZWFjdGlvblJlcXVlc3QSHQoKbWVzc2FnZV9pZBgBIAEoCVIJbWVzc2FnZUlkEhQKBW'
    'Vtb2ppGAIgASgJUgVlbW9qaQ==');

@$core.Deprecated('Use addReactionResponseDescriptor instead')
const AddReactionResponse$json = {
  '1': 'AddReactionResponse',
  '2': [
    {
      '1': 'message',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.ratatosk.v1.Message',
      '10': 'message'
    },
  ],
};

/// Descriptor for `AddReactionResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List addReactionResponseDescriptor = $convert.base64Decode(
    'ChNBZGRSZWFjdGlvblJlc3BvbnNlEi4KB21lc3NhZ2UYASABKAsyFC5yYXRhdG9zay52MS5NZX'
    'NzYWdlUgdtZXNzYWdl');

@$core.Deprecated('Use removeReactionRequestDescriptor instead')
const RemoveReactionRequest$json = {
  '1': 'RemoveReactionRequest',
  '2': [
    {'1': 'message_id', '3': 1, '4': 1, '5': 9, '10': 'messageId'},
    {'1': 'emoji', '3': 2, '4': 1, '5': 9, '10': 'emoji'},
  ],
};

/// Descriptor for `RemoveReactionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List removeReactionRequestDescriptor = $convert.base64Decode(
    'ChVSZW1vdmVSZWFjdGlvblJlcXVlc3QSHQoKbWVzc2FnZV9pZBgBIAEoCVIJbWVzc2FnZUlkEh'
    'QKBWVtb2ppGAIgASgJUgVlbW9qaQ==');

@$core.Deprecated('Use removeReactionResponseDescriptor instead')
const RemoveReactionResponse$json = {
  '1': 'RemoveReactionResponse',
  '2': [
    {
      '1': 'message',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.ratatosk.v1.Message',
      '10': 'message'
    },
  ],
};

/// Descriptor for `RemoveReactionResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List removeReactionResponseDescriptor =
    $convert.base64Decode(
        'ChZSZW1vdmVSZWFjdGlvblJlc3BvbnNlEi4KB21lc3NhZ2UYASABKAsyFC5yYXRhdG9zay52MS'
        '5NZXNzYWdlUgdtZXNzYWdl');

@$core.Deprecated('Use markReadRequestDescriptor instead')
const MarkReadRequest$json = {
  '1': 'MarkReadRequest',
  '2': [
    {'1': 'conversation_id', '3': 1, '4': 1, '5': 9, '10': 'conversationId'},
    {'1': 'up_to_seq', '3': 2, '4': 1, '5': 3, '10': 'upToSeq'},
  ],
};

/// Descriptor for `MarkReadRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List markReadRequestDescriptor = $convert.base64Decode(
    'Cg9NYXJrUmVhZFJlcXVlc3QSJwoPY29udmVyc2F0aW9uX2lkGAEgASgJUg5jb252ZXJzYXRpb2'
    '5JZBIaCgl1cF90b19zZXEYAiABKANSB3VwVG9TZXE=');

@$core.Deprecated('Use markReadResponseDescriptor instead')
const MarkReadResponse$json = {
  '1': 'MarkReadResponse',
  '2': [
    {'1': 'conversation_id', '3': 1, '4': 1, '5': 9, '10': 'conversationId'},
    {'1': 'last_read_seq', '3': 2, '4': 1, '5': 3, '10': 'lastReadSeq'},
    {'1': 'unread_count', '3': 3, '4': 1, '5': 5, '10': 'unreadCount'},
  ],
};

/// Descriptor for `MarkReadResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List markReadResponseDescriptor = $convert.base64Decode(
    'ChBNYXJrUmVhZFJlc3BvbnNlEicKD2NvbnZlcnNhdGlvbl9pZBgBIAEoCVIOY29udmVyc2F0aW'
    '9uSWQSIgoNbGFzdF9yZWFkX3NlcRgCIAEoA1ILbGFzdFJlYWRTZXESIQoMdW5yZWFkX2NvdW50'
    'GAMgASgFUgt1bnJlYWRDb3VudA==');

@$core.Deprecated('Use setTypingRequestDescriptor instead')
const SetTypingRequest$json = {
  '1': 'SetTypingRequest',
  '2': [
    {'1': 'conversation_id', '3': 1, '4': 1, '5': 9, '10': 'conversationId'},
    {'1': 'typing', '3': 2, '4': 1, '5': 8, '10': 'typing'},
  ],
};

/// Descriptor for `SetTypingRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setTypingRequestDescriptor = $convert.base64Decode(
    'ChBTZXRUeXBpbmdSZXF1ZXN0EicKD2NvbnZlcnNhdGlvbl9pZBgBIAEoCVIOY29udmVyc2F0aW'
    '9uSWQSFgoGdHlwaW5nGAIgASgIUgZ0eXBpbmc=');

@$core.Deprecated('Use setTypingResponseDescriptor instead')
const SetTypingResponse$json = {
  '1': 'SetTypingResponse',
};

/// Descriptor for `SetTypingResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setTypingResponseDescriptor =
    $convert.base64Decode('ChFTZXRUeXBpbmdSZXNwb25zZQ==');

@$core.Deprecated('Use searchMessagesRequestDescriptor instead')
const SearchMessagesRequest$json = {
  '1': 'SearchMessagesRequest',
  '2': [
    {'1': 'query', '3': 1, '4': 1, '5': 9, '10': 'query'},
    {'1': 'conversation_id', '3': 2, '4': 1, '5': 9, '10': 'conversationId'},
    {'1': 'limit', '3': 3, '4': 1, '5': 5, '10': 'limit'},
  ],
};

/// Descriptor for `SearchMessagesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List searchMessagesRequestDescriptor = $convert.base64Decode(
    'ChVTZWFyY2hNZXNzYWdlc1JlcXVlc3QSFAoFcXVlcnkYASABKAlSBXF1ZXJ5EicKD2NvbnZlcn'
    'NhdGlvbl9pZBgCIAEoCVIOY29udmVyc2F0aW9uSWQSFAoFbGltaXQYAyABKAVSBWxpbWl0');

@$core.Deprecated('Use searchResultDescriptor instead')
const SearchResult$json = {
  '1': 'SearchResult',
  '2': [
    {
      '1': 'message',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.ratatosk.v1.Message',
      '10': 'message'
    },
    {'1': 'conversation_id', '3': 2, '4': 1, '5': 9, '10': 'conversationId'},
    {
      '1': 'conversation_title',
      '3': 3,
      '4': 1,
      '5': 9,
      '10': 'conversationTitle'
    },
    {'1': 'sender_name', '3': 4, '4': 1, '5': 9, '10': 'senderName'},
    {'1': 'avatar_url', '3': 5, '4': 1, '5': 9, '10': 'avatarUrl'},
  ],
};

/// Descriptor for `SearchResult`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List searchResultDescriptor = $convert.base64Decode(
    'CgxTZWFyY2hSZXN1bHQSLgoHbWVzc2FnZRgBIAEoCzIULnJhdGF0b3NrLnYxLk1lc3NhZ2VSB2'
    '1lc3NhZ2USJwoPY29udmVyc2F0aW9uX2lkGAIgASgJUg5jb252ZXJzYXRpb25JZBItChJjb252'
    'ZXJzYXRpb25fdGl0bGUYAyABKAlSEWNvbnZlcnNhdGlvblRpdGxlEh8KC3NlbmRlcl9uYW1lGA'
    'QgASgJUgpzZW5kZXJOYW1lEh0KCmF2YXRhcl91cmwYBSABKAlSCWF2YXRhclVybA==');

@$core.Deprecated('Use searchMessagesResponseDescriptor instead')
const SearchMessagesResponse$json = {
  '1': 'SearchMessagesResponse',
  '2': [
    {
      '1': 'results',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.ratatosk.v1.SearchResult',
      '10': 'results'
    },
  ],
};

/// Descriptor for `SearchMessagesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List searchMessagesResponseDescriptor =
    $convert.base64Decode(
        'ChZTZWFyY2hNZXNzYWdlc1Jlc3BvbnNlEjMKB3Jlc3VsdHMYASADKAsyGS5yYXRhdG9zay52MS'
        '5TZWFyY2hSZXN1bHRSB3Jlc3VsdHM=');

@$core.Deprecated('Use uploadAttachmentRequestDescriptor instead')
const UploadAttachmentRequest$json = {
  '1': 'UploadAttachmentRequest',
  '2': [
    {'1': 'filename', '3': 1, '4': 1, '5': 9, '10': 'filename'},
    {'1': 'content_type', '3': 2, '4': 1, '5': 9, '10': 'contentType'},
    {'1': 'data', '3': 3, '4': 1, '5': 12, '10': 'data'},
    {'1': 'encrypted', '3': 4, '4': 1, '5': 8, '10': 'encrypted'},
  ],
};

/// Descriptor for `UploadAttachmentRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List uploadAttachmentRequestDescriptor = $convert.base64Decode(
    'ChdVcGxvYWRBdHRhY2htZW50UmVxdWVzdBIaCghmaWxlbmFtZRgBIAEoCVIIZmlsZW5hbWUSIQ'
    'oMY29udGVudF90eXBlGAIgASgJUgtjb250ZW50VHlwZRISCgRkYXRhGAMgASgMUgRkYXRhEhwK'
    'CWVuY3J5cHRlZBgEIAEoCFIJZW5jcnlwdGVk');

@$core.Deprecated('Use uploadAttachmentResponseDescriptor instead')
const UploadAttachmentResponse$json = {
  '1': 'UploadAttachmentResponse',
  '2': [
    {
      '1': 'attachment',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.ratatosk.v1.Attachment',
      '10': 'attachment'
    },
  ],
};

/// Descriptor for `UploadAttachmentResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List uploadAttachmentResponseDescriptor =
    $convert.base64Decode(
        'ChhVcGxvYWRBdHRhY2htZW50UmVzcG9uc2USNwoKYXR0YWNobWVudBgBIAEoCzIXLnJhdGF0b3'
        'NrLnYxLkF0dGFjaG1lbnRSCmF0dGFjaG1lbnQ=');

@$core.Deprecated('Use subscribeRequestDescriptor instead')
const SubscribeRequest$json = {
  '1': 'SubscribeRequest',
  '2': [
    {'1': 'since_seq', '3': 1, '4': 1, '5': 3, '10': 'sinceSeq'},
  ],
};

/// Descriptor for `SubscribeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List subscribeRequestDescriptor = $convert.base64Decode(
    'ChBTdWJzY3JpYmVSZXF1ZXN0EhsKCXNpbmNlX3NlcRgBIAEoA1IIc2luY2VTZXE=');

@$core.Deprecated('Use eventDescriptor instead')
const Event$json = {
  '1': 'Event',
  '2': [
    {'1': 'seq', '3': 1, '4': 1, '5': 3, '10': 'seq'},
    {
      '1': 'at',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'at'
    },
    {
      '1': 'hello',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.ratatosk.v1.Hello',
      '9': 0,
      '10': 'hello'
    },
    {
      '1': 'message',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.ratatosk.v1.MessageEvent',
      '9': 0,
      '10': 'message'
    },
    {
      '1': 'typing',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.ratatosk.v1.TypingEvent',
      '9': 0,
      '10': 'typing'
    },
    {
      '1': 'read',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.ratatosk.v1.ReadEvent',
      '9': 0,
      '10': 'read'
    },
    {
      '1': 'conversation',
      '3': 14,
      '4': 1,
      '5': 11,
      '6': '.ratatosk.v1.ConversationEvent',
      '9': 0,
      '10': 'conversation'
    },
    {
      '1': 'presence',
      '3': 15,
      '4': 1,
      '5': 11,
      '6': '.ratatosk.v1.PresenceEvent',
      '9': 0,
      '10': 'presence'
    },
    {
      '1': 'contact',
      '3': 16,
      '4': 1,
      '5': 11,
      '6': '.ratatosk.v1.ContactEvent',
      '9': 0,
      '10': 'contact'
    },
  ],
  '8': [
    {'1': 'payload'},
  ],
};

/// Descriptor for `Event`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List eventDescriptor = $convert.base64Decode(
    'CgVFdmVudBIQCgNzZXEYASABKANSA3NlcRIqCgJhdBgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi'
    '5UaW1lc3RhbXBSAmF0EioKBWhlbGxvGAogASgLMhIucmF0YXRvc2sudjEuSGVsbG9IAFIFaGVs'
    'bG8SNQoHbWVzc2FnZRgLIAEoCzIZLnJhdGF0b3NrLnYxLk1lc3NhZ2VFdmVudEgAUgdtZXNzYW'
    'dlEjIKBnR5cGluZxgMIAEoCzIYLnJhdGF0b3NrLnYxLlR5cGluZ0V2ZW50SABSBnR5cGluZxIs'
    'CgRyZWFkGA0gASgLMhYucmF0YXRvc2sudjEuUmVhZEV2ZW50SABSBHJlYWQSRAoMY29udmVyc2'
    'F0aW9uGA4gASgLMh4ucmF0YXRvc2sudjEuQ29udmVyc2F0aW9uRXZlbnRIAFIMY29udmVyc2F0'
    'aW9uEjgKCHByZXNlbmNlGA8gASgLMhoucmF0YXRvc2sudjEuUHJlc2VuY2VFdmVudEgAUghwcm'
    'VzZW5jZRI1Cgdjb250YWN0GBAgASgLMhkucmF0YXRvc2sudjEuQ29udGFjdEV2ZW50SABSB2Nv'
    'bnRhY3RCCQoHcGF5bG9hZA==');

@$core.Deprecated('Use helloDescriptor instead')
const Hello$json = {
  '1': 'Hello',
  '2': [
    {
      '1': 'user',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.ratatosk.v1.User',
      '10': 'user'
    },
    {
      '1': 'server_time',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'serverTime'
    },
  ],
};

/// Descriptor for `Hello`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List helloDescriptor = $convert.base64Decode(
    'CgVIZWxsbxIlCgR1c2VyGAEgASgLMhEucmF0YXRvc2sudjEuVXNlclIEdXNlchI7CgtzZXJ2ZX'
    'JfdGltZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCnNlcnZlclRpbWU=');

@$core.Deprecated('Use messageEventDescriptor instead')
const MessageEvent$json = {
  '1': 'MessageEvent',
  '2': [
    {
      '1': 'message',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.ratatosk.v1.Message',
      '10': 'message'
    },
  ],
};

/// Descriptor for `MessageEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List messageEventDescriptor = $convert.base64Decode(
    'CgxNZXNzYWdlRXZlbnQSLgoHbWVzc2FnZRgBIAEoCzIULnJhdGF0b3NrLnYxLk1lc3NhZ2VSB2'
    '1lc3NhZ2U=');

@$core.Deprecated('Use typingEventDescriptor instead')
const TypingEvent$json = {
  '1': 'TypingEvent',
  '2': [
    {'1': 'conversation_id', '3': 1, '4': 1, '5': 9, '10': 'conversationId'},
    {'1': 'user_id', '3': 2, '4': 1, '5': 9, '10': 'userId'},
    {'1': 'display_name', '3': 3, '4': 1, '5': 9, '10': 'displayName'},
    {'1': 'typing', '3': 4, '4': 1, '5': 8, '10': 'typing'},
  ],
};

/// Descriptor for `TypingEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List typingEventDescriptor = $convert.base64Decode(
    'CgtUeXBpbmdFdmVudBInCg9jb252ZXJzYXRpb25faWQYASABKAlSDmNvbnZlcnNhdGlvbklkEh'
    'cKB3VzZXJfaWQYAiABKAlSBnVzZXJJZBIhCgxkaXNwbGF5X25hbWUYAyABKAlSC2Rpc3BsYXlO'
    'YW1lEhYKBnR5cGluZxgEIAEoCFIGdHlwaW5n');

@$core.Deprecated('Use readEventDescriptor instead')
const ReadEvent$json = {
  '1': 'ReadEvent',
  '2': [
    {'1': 'conversation_id', '3': 1, '4': 1, '5': 9, '10': 'conversationId'},
    {'1': 'user_id', '3': 2, '4': 1, '5': 9, '10': 'userId'},
    {'1': 'last_read_seq', '3': 3, '4': 1, '5': 3, '10': 'lastReadSeq'},
  ],
};

/// Descriptor for `ReadEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List readEventDescriptor = $convert.base64Decode(
    'CglSZWFkRXZlbnQSJwoPY29udmVyc2F0aW9uX2lkGAEgASgJUg5jb252ZXJzYXRpb25JZBIXCg'
    'd1c2VyX2lkGAIgASgJUgZ1c2VySWQSIgoNbGFzdF9yZWFkX3NlcRgDIAEoA1ILbGFzdFJlYWRT'
    'ZXE=');

@$core.Deprecated('Use conversationEventDescriptor instead')
const ConversationEvent$json = {
  '1': 'ConversationEvent',
  '2': [
    {
      '1': 'conversation',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.ratatosk.v1.Conversation',
      '10': 'conversation'
    },
    {'1': 'created', '3': 2, '4': 1, '5': 8, '10': 'created'},
    {'1': 'removed', '3': 3, '4': 1, '5': 8, '10': 'removed'},
  ],
};

/// Descriptor for `ConversationEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List conversationEventDescriptor = $convert.base64Decode(
    'ChFDb252ZXJzYXRpb25FdmVudBI9Cgxjb252ZXJzYXRpb24YASABKAsyGS5yYXRhdG9zay52MS'
    '5Db252ZXJzYXRpb25SDGNvbnZlcnNhdGlvbhIYCgdjcmVhdGVkGAIgASgIUgdjcmVhdGVkEhgK'
    'B3JlbW92ZWQYAyABKAhSB3JlbW92ZWQ=');

@$core.Deprecated('Use presenceEventDescriptor instead')
const PresenceEvent$json = {
  '1': 'PresenceEvent',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 9, '10': 'userId'},
    {
      '1': 'presence',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.ratatosk.v1.Presence',
      '10': 'presence'
    },
    {
      '1': 'last_seen',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'lastSeen'
    },
  ],
};

/// Descriptor for `PresenceEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List presenceEventDescriptor = $convert.base64Decode(
    'Cg1QcmVzZW5jZUV2ZW50EhcKB3VzZXJfaWQYASABKAlSBnVzZXJJZBIxCghwcmVzZW5jZRgCIA'
    'EoDjIVLnJhdGF0b3NrLnYxLlByZXNlbmNlUghwcmVzZW5jZRI3CglsYXN0X3NlZW4YAyABKAsy'
    'Gi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUghsYXN0U2Vlbg==');

@$core.Deprecated('Use contactEventDescriptor instead')
const ContactEvent$json = {
  '1': 'ContactEvent',
  '2': [
    {'1': 'kind', '3': 1, '4': 1, '5': 9, '10': 'kind'},
    {
      '1': 'user',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.ratatosk.v1.User',
      '10': 'user'
    },
    {'1': 'conversation_id', '3': 3, '4': 1, '5': 9, '10': 'conversationId'},
  ],
};

/// Descriptor for `ContactEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List contactEventDescriptor = $convert.base64Decode(
    'CgxDb250YWN0RXZlbnQSEgoEa2luZBgBIAEoCVIEa2luZBIlCgR1c2VyGAIgASgLMhEucmF0YX'
    'Rvc2sudjEuVXNlclIEdXNlchInCg9jb252ZXJzYXRpb25faWQYAyABKAlSDmNvbnZlcnNhdGlv'
    'bklk');

const $core.Map<$core.String, $core.dynamic> ChatServiceBase$json = {
  '1': 'ChatService',
  '2': [
    {
      '1': 'ListConversations',
      '2': '.ratatosk.v1.ListConversationsRequest',
      '3': '.ratatosk.v1.ListConversationsResponse',
      '4': {}
    },
    {
      '1': 'GetConversation',
      '2': '.ratatosk.v1.GetConversationRequest',
      '3': '.ratatosk.v1.GetConversationResponse',
      '4': {}
    },
    {
      '1': 'CreateDirectConversation',
      '2': '.ratatosk.v1.CreateDirectConversationRequest',
      '3': '.ratatosk.v1.CreateDirectConversationResponse',
      '4': {}
    },
    {
      '1': 'CreateGroupConversation',
      '2': '.ratatosk.v1.CreateGroupConversationRequest',
      '3': '.ratatosk.v1.CreateGroupConversationResponse',
      '4': {}
    },
    {
      '1': 'UpdateConversation',
      '2': '.ratatosk.v1.UpdateConversationRequest',
      '3': '.ratatosk.v1.UpdateConversationResponse',
      '4': {}
    },
    {
      '1': 'AddMembers',
      '2': '.ratatosk.v1.AddMembersRequest',
      '3': '.ratatosk.v1.AddMembersResponse',
      '4': {}
    },
    {
      '1': 'RemoveMember',
      '2': '.ratatosk.v1.RemoveMemberRequest',
      '3': '.ratatosk.v1.RemoveMemberResponse',
      '4': {}
    },
    {
      '1': 'ListMessages',
      '2': '.ratatosk.v1.ListMessagesRequest',
      '3': '.ratatosk.v1.ListMessagesResponse',
      '4': {}
    },
    {
      '1': 'SendMessage',
      '2': '.ratatosk.v1.SendMessageRequest',
      '3': '.ratatosk.v1.SendMessageResponse',
      '4': {}
    },
    {
      '1': 'EditMessage',
      '2': '.ratatosk.v1.EditMessageRequest',
      '3': '.ratatosk.v1.EditMessageResponse',
      '4': {}
    },
    {
      '1': 'DeleteMessage',
      '2': '.ratatosk.v1.DeleteMessageRequest',
      '3': '.ratatosk.v1.DeleteMessageResponse',
      '4': {}
    },
    {
      '1': 'AddReaction',
      '2': '.ratatosk.v1.AddReactionRequest',
      '3': '.ratatosk.v1.AddReactionResponse',
      '4': {}
    },
    {
      '1': 'RemoveReaction',
      '2': '.ratatosk.v1.RemoveReactionRequest',
      '3': '.ratatosk.v1.RemoveReactionResponse',
      '4': {}
    },
    {
      '1': 'MarkRead',
      '2': '.ratatosk.v1.MarkReadRequest',
      '3': '.ratatosk.v1.MarkReadResponse',
      '4': {}
    },
    {
      '1': 'SetTyping',
      '2': '.ratatosk.v1.SetTypingRequest',
      '3': '.ratatosk.v1.SetTypingResponse',
      '4': {}
    },
    {
      '1': 'SearchMessages',
      '2': '.ratatosk.v1.SearchMessagesRequest',
      '3': '.ratatosk.v1.SearchMessagesResponse',
      '4': {}
    },
    {
      '1': 'UploadAttachment',
      '2': '.ratatosk.v1.UploadAttachmentRequest',
      '3': '.ratatosk.v1.UploadAttachmentResponse',
      '4': {}
    },
    {
      '1': 'Subscribe',
      '2': '.ratatosk.v1.SubscribeRequest',
      '3': '.ratatosk.v1.Event',
      '4': {},
      '6': true
    },
  ],
};

@$core.Deprecated('Use chatServiceDescriptor instead')
const $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
    ChatServiceBase$messageJson = {
  '.ratatosk.v1.ListConversationsRequest': ListConversationsRequest$json,
  '.ratatosk.v1.ListConversationsResponse': ListConversationsResponse$json,
  '.ratatosk.v1.Conversation': Conversation$json,
  '.ratatosk.v1.Member': Member$json,
  '.ratatosk.v1.User': $0.User$json,
  '.google.protobuf.Timestamp': $1.Timestamp$json,
  '.ratatosk.v1.Message': Message$json,
  '.ratatosk.v1.Attachment': $0.Attachment$json,
  '.ratatosk.v1.Reaction': Reaction$json,
  '.ratatosk.v1.ReplyPreview': $0.ReplyPreview$json,
  '.ratatosk.v1.GetConversationRequest': GetConversationRequest$json,
  '.ratatosk.v1.GetConversationResponse': GetConversationResponse$json,
  '.ratatosk.v1.CreateDirectConversationRequest':
      CreateDirectConversationRequest$json,
  '.ratatosk.v1.CreateDirectConversationResponse':
      CreateDirectConversationResponse$json,
  '.ratatosk.v1.CreateGroupConversationRequest':
      CreateGroupConversationRequest$json,
  '.ratatosk.v1.CreateGroupConversationResponse':
      CreateGroupConversationResponse$json,
  '.ratatosk.v1.UpdateConversationRequest': UpdateConversationRequest$json,
  '.ratatosk.v1.UpdateConversationResponse': UpdateConversationResponse$json,
  '.ratatosk.v1.AddMembersRequest': AddMembersRequest$json,
  '.ratatosk.v1.AddMembersResponse': AddMembersResponse$json,
  '.ratatosk.v1.RemoveMemberRequest': RemoveMemberRequest$json,
  '.ratatosk.v1.RemoveMemberResponse': RemoveMemberResponse$json,
  '.ratatosk.v1.ListMessagesRequest': ListMessagesRequest$json,
  '.ratatosk.v1.ListMessagesResponse': ListMessagesResponse$json,
  '.ratatosk.v1.SendMessageRequest': SendMessageRequest$json,
  '.ratatosk.v1.SendMessageResponse': SendMessageResponse$json,
  '.ratatosk.v1.EditMessageRequest': EditMessageRequest$json,
  '.ratatosk.v1.EditMessageResponse': EditMessageResponse$json,
  '.ratatosk.v1.DeleteMessageRequest': DeleteMessageRequest$json,
  '.ratatosk.v1.DeleteMessageResponse': DeleteMessageResponse$json,
  '.ratatosk.v1.AddReactionRequest': AddReactionRequest$json,
  '.ratatosk.v1.AddReactionResponse': AddReactionResponse$json,
  '.ratatosk.v1.RemoveReactionRequest': RemoveReactionRequest$json,
  '.ratatosk.v1.RemoveReactionResponse': RemoveReactionResponse$json,
  '.ratatosk.v1.MarkReadRequest': MarkReadRequest$json,
  '.ratatosk.v1.MarkReadResponse': MarkReadResponse$json,
  '.ratatosk.v1.SetTypingRequest': SetTypingRequest$json,
  '.ratatosk.v1.SetTypingResponse': SetTypingResponse$json,
  '.ratatosk.v1.SearchMessagesRequest': SearchMessagesRequest$json,
  '.ratatosk.v1.SearchMessagesResponse': SearchMessagesResponse$json,
  '.ratatosk.v1.SearchResult': SearchResult$json,
  '.ratatosk.v1.UploadAttachmentRequest': UploadAttachmentRequest$json,
  '.ratatosk.v1.UploadAttachmentResponse': UploadAttachmentResponse$json,
  '.ratatosk.v1.SubscribeRequest': SubscribeRequest$json,
  '.ratatosk.v1.Event': Event$json,
  '.ratatosk.v1.Hello': Hello$json,
  '.ratatosk.v1.MessageEvent': MessageEvent$json,
  '.ratatosk.v1.TypingEvent': TypingEvent$json,
  '.ratatosk.v1.ReadEvent': ReadEvent$json,
  '.ratatosk.v1.ConversationEvent': ConversationEvent$json,
  '.ratatosk.v1.PresenceEvent': PresenceEvent$json,
  '.ratatosk.v1.ContactEvent': ContactEvent$json,
};

/// Descriptor for `ChatService`. Decode as a `google.protobuf.ServiceDescriptorProto`.
final $typed_data.Uint8List chatServiceDescriptor = $convert.base64Decode(
    'CgtDaGF0U2VydmljZRJkChFMaXN0Q29udmVyc2F0aW9ucxIlLnJhdGF0b3NrLnYxLkxpc3RDb2'
    '52ZXJzYXRpb25zUmVxdWVzdBomLnJhdGF0b3NrLnYxLkxpc3RDb252ZXJzYXRpb25zUmVzcG9u'
    'c2UiABJeCg9HZXRDb252ZXJzYXRpb24SIy5yYXRhdG9zay52MS5HZXRDb252ZXJzYXRpb25SZX'
    'F1ZXN0GiQucmF0YXRvc2sudjEuR2V0Q29udmVyc2F0aW9uUmVzcG9uc2UiABJ5ChhDcmVhdGVE'
    'aXJlY3RDb252ZXJzYXRpb24SLC5yYXRhdG9zay52MS5DcmVhdGVEaXJlY3RDb252ZXJzYXRpb2'
    '5SZXF1ZXN0Gi0ucmF0YXRvc2sudjEuQ3JlYXRlRGlyZWN0Q29udmVyc2F0aW9uUmVzcG9uc2Ui'
    'ABJ2ChdDcmVhdGVHcm91cENvbnZlcnNhdGlvbhIrLnJhdGF0b3NrLnYxLkNyZWF0ZUdyb3VwQ2'
    '9udmVyc2F0aW9uUmVxdWVzdBosLnJhdGF0b3NrLnYxLkNyZWF0ZUdyb3VwQ29udmVyc2F0aW9u'
    'UmVzcG9uc2UiABJnChJVcGRhdGVDb252ZXJzYXRpb24SJi5yYXRhdG9zay52MS5VcGRhdGVDb2'
    '52ZXJzYXRpb25SZXF1ZXN0GicucmF0YXRvc2sudjEuVXBkYXRlQ29udmVyc2F0aW9uUmVzcG9u'
    'c2UiABJPCgpBZGRNZW1iZXJzEh4ucmF0YXRvc2sudjEuQWRkTWVtYmVyc1JlcXVlc3QaHy5yYX'
    'RhdG9zay52MS5BZGRNZW1iZXJzUmVzcG9uc2UiABJVCgxSZW1vdmVNZW1iZXISIC5yYXRhdG9z'
    'ay52MS5SZW1vdmVNZW1iZXJSZXF1ZXN0GiEucmF0YXRvc2sudjEuUmVtb3ZlTWVtYmVyUmVzcG'
    '9uc2UiABJVCgxMaXN0TWVzc2FnZXMSIC5yYXRhdG9zay52MS5MaXN0TWVzc2FnZXNSZXF1ZXN0'
    'GiEucmF0YXRvc2sudjEuTGlzdE1lc3NhZ2VzUmVzcG9uc2UiABJSCgtTZW5kTWVzc2FnZRIfLn'
    'JhdGF0b3NrLnYxLlNlbmRNZXNzYWdlUmVxdWVzdBogLnJhdGF0b3NrLnYxLlNlbmRNZXNzYWdl'
    'UmVzcG9uc2UiABJSCgtFZGl0TWVzc2FnZRIfLnJhdGF0b3NrLnYxLkVkaXRNZXNzYWdlUmVxdW'
    'VzdBogLnJhdGF0b3NrLnYxLkVkaXRNZXNzYWdlUmVzcG9uc2UiABJYCg1EZWxldGVNZXNzYWdl'
    'EiEucmF0YXRvc2sudjEuRGVsZXRlTWVzc2FnZVJlcXVlc3QaIi5yYXRhdG9zay52MS5EZWxldG'
    'VNZXNzYWdlUmVzcG9uc2UiABJSCgtBZGRSZWFjdGlvbhIfLnJhdGF0b3NrLnYxLkFkZFJlYWN0'
    'aW9uUmVxdWVzdBogLnJhdGF0b3NrLnYxLkFkZFJlYWN0aW9uUmVzcG9uc2UiABJbCg5SZW1vdm'
    'VSZWFjdGlvbhIiLnJhdGF0b3NrLnYxLlJlbW92ZVJlYWN0aW9uUmVxdWVzdBojLnJhdGF0b3Nr'
    'LnYxLlJlbW92ZVJlYWN0aW9uUmVzcG9uc2UiABJJCghNYXJrUmVhZBIcLnJhdGF0b3NrLnYxLk'
    '1hcmtSZWFkUmVxdWVzdBodLnJhdGF0b3NrLnYxLk1hcmtSZWFkUmVzcG9uc2UiABJMCglTZXRU'
    'eXBpbmcSHS5yYXRhdG9zay52MS5TZXRUeXBpbmdSZXF1ZXN0Gh4ucmF0YXRvc2sudjEuU2V0VH'
    'lwaW5nUmVzcG9uc2UiABJbCg5TZWFyY2hNZXNzYWdlcxIiLnJhdGF0b3NrLnYxLlNlYXJjaE1l'
    'c3NhZ2VzUmVxdWVzdBojLnJhdGF0b3NrLnYxLlNlYXJjaE1lc3NhZ2VzUmVzcG9uc2UiABJhCh'
    'BVcGxvYWRBdHRhY2htZW50EiQucmF0YXRvc2sudjEuVXBsb2FkQXR0YWNobWVudFJlcXVlc3Qa'
    'JS5yYXRhdG9zay52MS5VcGxvYWRBdHRhY2htZW50UmVzcG9uc2UiABJCCglTdWJzY3JpYmUSHS'
    '5yYXRhdG9zay52MS5TdWJzY3JpYmVSZXF1ZXN0GhIucmF0YXRvc2sudjEuRXZlbnQiADAB');
