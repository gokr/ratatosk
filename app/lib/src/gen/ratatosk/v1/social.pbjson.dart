// This is a generated file - do not edit.
//
// Generated from ratatosk/v1/social.proto.

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

import 'chat.pbjson.dart' as $2;
import 'common.pbjson.dart' as $0;

@$core.Deprecated('Use contactDescriptor instead')
const Contact$json = {
  '1': 'Contact',
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
      '1': 'since',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'since'
    },
    {'1': 'conversation_id', '3': 3, '4': 1, '5': 9, '10': 'conversationId'},
    {'1': 'blocked', '3': 4, '4': 1, '5': 8, '10': 'blocked'},
  ],
};

/// Descriptor for `Contact`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List contactDescriptor = $convert.base64Decode(
    'CgdDb250YWN0EiUKBHVzZXIYASABKAsyES5yYXRhdG9zay52MS5Vc2VyUgR1c2VyEjAKBXNpbm'
    'NlGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIFc2luY2USJwoPY29udmVyc2F0'
    'aW9uX2lkGAMgASgJUg5jb252ZXJzYXRpb25JZBIYCgdibG9ja2VkGAQgASgIUgdibG9ja2Vk');

@$core.Deprecated('Use inviteDescriptor instead')
const Invite$json = {
  '1': 'Invite',
  '2': [
    {'1': 'code', '3': 1, '4': 1, '5': 9, '10': 'code'},
    {'1': 'url', '3': 2, '4': 1, '5': 9, '10': 'url'},
    {
      '1': 'created_at',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'createdAt'
    },
    {
      '1': 'expires_at',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'expiresAt'
    },
    {'1': 'max_uses', '3': 5, '4': 1, '5': 5, '10': 'maxUses'},
    {'1': 'uses', '3': 6, '4': 1, '5': 5, '10': 'uses'},
    {'1': 'revoked', '3': 7, '4': 1, '5': 8, '10': 'revoked'},
    {'1': 'redeemed_by', '3': 8, '4': 3, '5': 9, '10': 'redeemedBy'},
    {'1': 'valid', '3': 9, '4': 1, '5': 8, '10': 'valid'},
    {'1': 'invalid_reason', '3': 10, '4': 1, '5': 9, '10': 'invalidReason'},
  ],
};

/// Descriptor for `Invite`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List inviteDescriptor = $convert.base64Decode(
    'CgZJbnZpdGUSEgoEY29kZRgBIAEoCVIEY29kZRIQCgN1cmwYAiABKAlSA3VybBI5CgpjcmVhdG'
    'VkX2F0GAMgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIJY3JlYXRlZEF0EjkKCmV4'
    'cGlyZXNfYXQYBCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUglleHBpcmVzQXQSGQ'
    'oIbWF4X3VzZXMYBSABKAVSB21heFVzZXMSEgoEdXNlcxgGIAEoBVIEdXNlcxIYCgdyZXZva2Vk'
    'GAcgASgIUgdyZXZva2VkEh8KC3JlZGVlbWVkX2J5GAggAygJUgpyZWRlZW1lZEJ5EhQKBXZhbG'
    'lkGAkgASgIUgV2YWxpZBIlCg5pbnZhbGlkX3JlYXNvbhgKIAEoCVINaW52YWxpZFJlYXNvbg==');

@$core.Deprecated('Use listContactsRequestDescriptor instead')
const ListContactsRequest$json = {
  '1': 'ListContactsRequest',
};

/// Descriptor for `ListContactsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listContactsRequestDescriptor =
    $convert.base64Decode('ChNMaXN0Q29udGFjdHNSZXF1ZXN0');

@$core.Deprecated('Use listContactsResponseDescriptor instead')
const ListContactsResponse$json = {
  '1': 'ListContactsResponse',
  '2': [
    {
      '1': 'contacts',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.ratatosk.v1.Contact',
      '10': 'contacts'
    },
  ],
};

/// Descriptor for `ListContactsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listContactsResponseDescriptor = $convert.base64Decode(
    'ChRMaXN0Q29udGFjdHNSZXNwb25zZRIwCghjb250YWN0cxgBIAMoCzIULnJhdGF0b3NrLnYxLk'
    'NvbnRhY3RSCGNvbnRhY3Rz');

@$core.Deprecated('Use addContactRequestDescriptor instead')
const AddContactRequest$json = {
  '1': 'AddContactRequest',
  '2': [
    {'1': 'username', '3': 1, '4': 1, '5': 9, '10': 'username'},
  ],
};

/// Descriptor for `AddContactRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List addContactRequestDescriptor = $convert.base64Decode(
    'ChFBZGRDb250YWN0UmVxdWVzdBIaCgh1c2VybmFtZRgBIAEoCVIIdXNlcm5hbWU=');

@$core.Deprecated('Use addContactResponseDescriptor instead')
const AddContactResponse$json = {
  '1': 'AddContactResponse',
  '2': [
    {
      '1': 'contact',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.ratatosk.v1.Contact',
      '10': 'contact'
    },
    {
      '1': 'conversation',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.ratatosk.v1.Conversation',
      '10': 'conversation'
    },
  ],
};

/// Descriptor for `AddContactResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List addContactResponseDescriptor = $convert.base64Decode(
    'ChJBZGRDb250YWN0UmVzcG9uc2USLgoHY29udGFjdBgBIAEoCzIULnJhdGF0b3NrLnYxLkNvbn'
    'RhY3RSB2NvbnRhY3QSPQoMY29udmVyc2F0aW9uGAIgASgLMhkucmF0YXRvc2sudjEuQ29udmVy'
    'c2F0aW9uUgxjb252ZXJzYXRpb24=');

@$core.Deprecated('Use removeContactRequestDescriptor instead')
const RemoveContactRequest$json = {
  '1': 'RemoveContactRequest',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 9, '10': 'userId'},
  ],
};

/// Descriptor for `RemoveContactRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List removeContactRequestDescriptor =
    $convert.base64Decode(
        'ChRSZW1vdmVDb250YWN0UmVxdWVzdBIXCgd1c2VyX2lkGAEgASgJUgZ1c2VySWQ=');

@$core.Deprecated('Use removeContactResponseDescriptor instead')
const RemoveContactResponse$json = {
  '1': 'RemoveContactResponse',
};

/// Descriptor for `RemoveContactResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List removeContactResponseDescriptor =
    $convert.base64Decode('ChVSZW1vdmVDb250YWN0UmVzcG9uc2U=');

@$core.Deprecated('Use searchUsersRequestDescriptor instead')
const SearchUsersRequest$json = {
  '1': 'SearchUsersRequest',
  '2': [
    {'1': 'query', '3': 1, '4': 1, '5': 9, '10': 'query'},
    {'1': 'limit', '3': 2, '4': 1, '5': 5, '10': 'limit'},
  ],
};

/// Descriptor for `SearchUsersRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List searchUsersRequestDescriptor = $convert.base64Decode(
    'ChJTZWFyY2hVc2Vyc1JlcXVlc3QSFAoFcXVlcnkYASABKAlSBXF1ZXJ5EhQKBWxpbWl0GAIgAS'
    'gFUgVsaW1pdA==');

@$core.Deprecated('Use searchUsersResponseDescriptor instead')
const SearchUsersResponse$json = {
  '1': 'SearchUsersResponse',
  '2': [
    {
      '1': 'users',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.ratatosk.v1.User',
      '10': 'users'
    },
  ],
};

/// Descriptor for `SearchUsersResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List searchUsersResponseDescriptor = $convert.base64Decode(
    'ChNTZWFyY2hVc2Vyc1Jlc3BvbnNlEicKBXVzZXJzGAEgAygLMhEucmF0YXRvc2sudjEuVXNlcl'
    'IFdXNlcnM=');

@$core.Deprecated('Use createInviteRequestDescriptor instead')
const CreateInviteRequest$json = {
  '1': 'CreateInviteRequest',
  '2': [
    {'1': 'expires_in_hours', '3': 1, '4': 1, '5': 5, '10': 'expiresInHours'},
    {'1': 'max_uses', '3': 2, '4': 1, '5': 5, '10': 'maxUses'},
  ],
};

/// Descriptor for `CreateInviteRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createInviteRequestDescriptor = $convert.base64Decode(
    'ChNDcmVhdGVJbnZpdGVSZXF1ZXN0EigKEGV4cGlyZXNfaW5faG91cnMYASABKAVSDmV4cGlyZX'
    'NJbkhvdXJzEhkKCG1heF91c2VzGAIgASgFUgdtYXhVc2Vz');

@$core.Deprecated('Use createInviteResponseDescriptor instead')
const CreateInviteResponse$json = {
  '1': 'CreateInviteResponse',
  '2': [
    {
      '1': 'invite',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.ratatosk.v1.Invite',
      '10': 'invite'
    },
  ],
};

/// Descriptor for `CreateInviteResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createInviteResponseDescriptor = $convert.base64Decode(
    'ChRDcmVhdGVJbnZpdGVSZXNwb25zZRIrCgZpbnZpdGUYASABKAsyEy5yYXRhdG9zay52MS5Jbn'
    'ZpdGVSBmludml0ZQ==');

@$core.Deprecated('Use listInvitesRequestDescriptor instead')
const ListInvitesRequest$json = {
  '1': 'ListInvitesRequest',
};

/// Descriptor for `ListInvitesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listInvitesRequestDescriptor =
    $convert.base64Decode('ChJMaXN0SW52aXRlc1JlcXVlc3Q=');

@$core.Deprecated('Use listInvitesResponseDescriptor instead')
const ListInvitesResponse$json = {
  '1': 'ListInvitesResponse',
  '2': [
    {
      '1': 'invites',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.ratatosk.v1.Invite',
      '10': 'invites'
    },
  ],
};

/// Descriptor for `ListInvitesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listInvitesResponseDescriptor = $convert.base64Decode(
    'ChNMaXN0SW52aXRlc1Jlc3BvbnNlEi0KB2ludml0ZXMYASADKAsyEy5yYXRhdG9zay52MS5Jbn'
    'ZpdGVSB2ludml0ZXM=');

@$core.Deprecated('Use revokeInviteRequestDescriptor instead')
const RevokeInviteRequest$json = {
  '1': 'RevokeInviteRequest',
  '2': [
    {'1': 'code', '3': 1, '4': 1, '5': 9, '10': 'code'},
  ],
};

/// Descriptor for `RevokeInviteRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List revokeInviteRequestDescriptor = $convert
    .base64Decode('ChNSZXZva2VJbnZpdGVSZXF1ZXN0EhIKBGNvZGUYASABKAlSBGNvZGU=');

@$core.Deprecated('Use revokeInviteResponseDescriptor instead')
const RevokeInviteResponse$json = {
  '1': 'RevokeInviteResponse',
};

/// Descriptor for `RevokeInviteResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List revokeInviteResponseDescriptor =
    $convert.base64Decode('ChRSZXZva2VJbnZpdGVSZXNwb25zZQ==');

@$core.Deprecated('Use previewInviteRequestDescriptor instead')
const PreviewInviteRequest$json = {
  '1': 'PreviewInviteRequest',
  '2': [
    {'1': 'code', '3': 1, '4': 1, '5': 9, '10': 'code'},
  ],
};

/// Descriptor for `PreviewInviteRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List previewInviteRequestDescriptor = $convert
    .base64Decode('ChRQcmV2aWV3SW52aXRlUmVxdWVzdBISCgRjb2RlGAEgASgJUgRjb2Rl');

@$core.Deprecated('Use previewInviteResponseDescriptor instead')
const PreviewInviteResponse$json = {
  '1': 'PreviewInviteResponse',
  '2': [
    {'1': 'valid', '3': 1, '4': 1, '5': 8, '10': 'valid'},
    {
      '1': 'inviter',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.ratatosk.v1.User',
      '10': 'inviter'
    },
    {'1': 'reason', '3': 3, '4': 1, '5': 9, '10': 'reason'},
    {
      '1': 'expires_at',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'expiresAt'
    },
    {'1': 'remaining_uses', '3': 5, '4': 1, '5': 5, '10': 'remainingUses'},
    {'1': 'already_contacts', '3': 6, '4': 1, '5': 8, '10': 'alreadyContacts'},
  ],
};

/// Descriptor for `PreviewInviteResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List previewInviteResponseDescriptor = $convert.base64Decode(
    'ChVQcmV2aWV3SW52aXRlUmVzcG9uc2USFAoFdmFsaWQYASABKAhSBXZhbGlkEisKB2ludml0ZX'
    'IYAiABKAsyES5yYXRhdG9zay52MS5Vc2VyUgdpbnZpdGVyEhYKBnJlYXNvbhgDIAEoCVIGcmVh'
    'c29uEjkKCmV4cGlyZXNfYXQYBCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUglleH'
    'BpcmVzQXQSJQoOcmVtYWluaW5nX3VzZXMYBSABKAVSDXJlbWFpbmluZ1VzZXMSKQoQYWxyZWFk'
    'eV9jb250YWN0cxgGIAEoCFIPYWxyZWFkeUNvbnRhY3Rz');

@$core.Deprecated('Use redeemInviteRequestDescriptor instead')
const RedeemInviteRequest$json = {
  '1': 'RedeemInviteRequest',
  '2': [
    {'1': 'code', '3': 1, '4': 1, '5': 9, '10': 'code'},
  ],
};

/// Descriptor for `RedeemInviteRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List redeemInviteRequestDescriptor = $convert
    .base64Decode('ChNSZWRlZW1JbnZpdGVSZXF1ZXN0EhIKBGNvZGUYASABKAlSBGNvZGU=');

@$core.Deprecated('Use redeemInviteResponseDescriptor instead')
const RedeemInviteResponse$json = {
  '1': 'RedeemInviteResponse',
  '2': [
    {
      '1': 'inviter',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.ratatosk.v1.User',
      '10': 'inviter'
    },
    {
      '1': 'conversation',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.ratatosk.v1.Conversation',
      '10': 'conversation'
    },
  ],
};

/// Descriptor for `RedeemInviteResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List redeemInviteResponseDescriptor = $convert.base64Decode(
    'ChRSZWRlZW1JbnZpdGVSZXNwb25zZRIrCgdpbnZpdGVyGAEgASgLMhEucmF0YXRvc2sudjEuVX'
    'NlclIHaW52aXRlchI9Cgxjb252ZXJzYXRpb24YAiABKAsyGS5yYXRhdG9zay52MS5Db252ZXJz'
    'YXRpb25SDGNvbnZlcnNhdGlvbg==');

const $core.Map<$core.String, $core.dynamic> SocialServiceBase$json = {
  '1': 'SocialService',
  '2': [
    {
      '1': 'ListContacts',
      '2': '.ratatosk.v1.ListContactsRequest',
      '3': '.ratatosk.v1.ListContactsResponse',
      '4': {}
    },
    {
      '1': 'AddContact',
      '2': '.ratatosk.v1.AddContactRequest',
      '3': '.ratatosk.v1.AddContactResponse',
      '4': {}
    },
    {
      '1': 'RemoveContact',
      '2': '.ratatosk.v1.RemoveContactRequest',
      '3': '.ratatosk.v1.RemoveContactResponse',
      '4': {}
    },
    {
      '1': 'SearchUsers',
      '2': '.ratatosk.v1.SearchUsersRequest',
      '3': '.ratatosk.v1.SearchUsersResponse',
      '4': {}
    },
    {
      '1': 'CreateInvite',
      '2': '.ratatosk.v1.CreateInviteRequest',
      '3': '.ratatosk.v1.CreateInviteResponse',
      '4': {}
    },
    {
      '1': 'ListInvites',
      '2': '.ratatosk.v1.ListInvitesRequest',
      '3': '.ratatosk.v1.ListInvitesResponse',
      '4': {}
    },
    {
      '1': 'RevokeInvite',
      '2': '.ratatosk.v1.RevokeInviteRequest',
      '3': '.ratatosk.v1.RevokeInviteResponse',
      '4': {}
    },
    {
      '1': 'PreviewInvite',
      '2': '.ratatosk.v1.PreviewInviteRequest',
      '3': '.ratatosk.v1.PreviewInviteResponse',
      '4': {}
    },
    {
      '1': 'RedeemInvite',
      '2': '.ratatosk.v1.RedeemInviteRequest',
      '3': '.ratatosk.v1.RedeemInviteResponse',
      '4': {}
    },
  ],
};

@$core.Deprecated('Use socialServiceDescriptor instead')
const $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
    SocialServiceBase$messageJson = {
  '.ratatosk.v1.ListContactsRequest': ListContactsRequest$json,
  '.ratatosk.v1.ListContactsResponse': ListContactsResponse$json,
  '.ratatosk.v1.Contact': Contact$json,
  '.ratatosk.v1.User': $0.User$json,
  '.google.protobuf.Timestamp': $1.Timestamp$json,
  '.ratatosk.v1.AddContactRequest': AddContactRequest$json,
  '.ratatosk.v1.AddContactResponse': AddContactResponse$json,
  '.ratatosk.v1.Conversation': $2.Conversation$json,
  '.ratatosk.v1.Member': $2.Member$json,
  '.ratatosk.v1.Message': $2.Message$json,
  '.ratatosk.v1.Attachment': $0.Attachment$json,
  '.ratatosk.v1.Reaction': $2.Reaction$json,
  '.ratatosk.v1.ReplyPreview': $0.ReplyPreview$json,
  '.ratatosk.v1.RemoveContactRequest': RemoveContactRequest$json,
  '.ratatosk.v1.RemoveContactResponse': RemoveContactResponse$json,
  '.ratatosk.v1.SearchUsersRequest': SearchUsersRequest$json,
  '.ratatosk.v1.SearchUsersResponse': SearchUsersResponse$json,
  '.ratatosk.v1.CreateInviteRequest': CreateInviteRequest$json,
  '.ratatosk.v1.CreateInviteResponse': CreateInviteResponse$json,
  '.ratatosk.v1.Invite': Invite$json,
  '.ratatosk.v1.ListInvitesRequest': ListInvitesRequest$json,
  '.ratatosk.v1.ListInvitesResponse': ListInvitesResponse$json,
  '.ratatosk.v1.RevokeInviteRequest': RevokeInviteRequest$json,
  '.ratatosk.v1.RevokeInviteResponse': RevokeInviteResponse$json,
  '.ratatosk.v1.PreviewInviteRequest': PreviewInviteRequest$json,
  '.ratatosk.v1.PreviewInviteResponse': PreviewInviteResponse$json,
  '.ratatosk.v1.RedeemInviteRequest': RedeemInviteRequest$json,
  '.ratatosk.v1.RedeemInviteResponse': RedeemInviteResponse$json,
};

/// Descriptor for `SocialService`. Decode as a `google.protobuf.ServiceDescriptorProto`.
final $typed_data.Uint8List socialServiceDescriptor = $convert.base64Decode(
    'Cg1Tb2NpYWxTZXJ2aWNlElUKDExpc3RDb250YWN0cxIgLnJhdGF0b3NrLnYxLkxpc3RDb250YW'
    'N0c1JlcXVlc3QaIS5yYXRhdG9zay52MS5MaXN0Q29udGFjdHNSZXNwb25zZSIAEk8KCkFkZENv'
    'bnRhY3QSHi5yYXRhdG9zay52MS5BZGRDb250YWN0UmVxdWVzdBofLnJhdGF0b3NrLnYxLkFkZE'
    'NvbnRhY3RSZXNwb25zZSIAElgKDVJlbW92ZUNvbnRhY3QSIS5yYXRhdG9zay52MS5SZW1vdmVD'
    'b250YWN0UmVxdWVzdBoiLnJhdGF0b3NrLnYxLlJlbW92ZUNvbnRhY3RSZXNwb25zZSIAElIKC1'
    'NlYXJjaFVzZXJzEh8ucmF0YXRvc2sudjEuU2VhcmNoVXNlcnNSZXF1ZXN0GiAucmF0YXRvc2su'
    'djEuU2VhcmNoVXNlcnNSZXNwb25zZSIAElUKDENyZWF0ZUludml0ZRIgLnJhdGF0b3NrLnYxLk'
    'NyZWF0ZUludml0ZVJlcXVlc3QaIS5yYXRhdG9zay52MS5DcmVhdGVJbnZpdGVSZXNwb25zZSIA'
    'ElIKC0xpc3RJbnZpdGVzEh8ucmF0YXRvc2sudjEuTGlzdEludml0ZXNSZXF1ZXN0GiAucmF0YX'
    'Rvc2sudjEuTGlzdEludml0ZXNSZXNwb25zZSIAElUKDFJldm9rZUludml0ZRIgLnJhdGF0b3Nr'
    'LnYxLlJldm9rZUludml0ZVJlcXVlc3QaIS5yYXRhdG9zay52MS5SZXZva2VJbnZpdGVSZXNwb2'
    '5zZSIAElgKDVByZXZpZXdJbnZpdGUSIS5yYXRhdG9zay52MS5QcmV2aWV3SW52aXRlUmVxdWVz'
    'dBoiLnJhdGF0b3NrLnYxLlByZXZpZXdJbnZpdGVSZXNwb25zZSIAElUKDFJlZGVlbUludml0ZR'
    'IgLnJhdGF0b3NrLnYxLlJlZGVlbUludml0ZVJlcXVlc3QaIS5yYXRhdG9zay52MS5SZWRlZW1J'
    'bnZpdGVSZXNwb25zZSIA');
