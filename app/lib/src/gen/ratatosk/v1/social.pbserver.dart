// This is a generated file - do not edit.
//
// Generated from ratatosk/v1/social.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'social.pb.dart' as $3;
import 'social.pbjson.dart';

export 'social.pb.dart';

abstract class SocialServiceBase extends $pb.GeneratedService {
  $async.Future<$3.ListContactsResponse> listContacts(
      $pb.ServerContext ctx, $3.ListContactsRequest request);
  $async.Future<$3.AddContactResponse> addContact(
      $pb.ServerContext ctx, $3.AddContactRequest request);
  $async.Future<$3.RemoveContactResponse> removeContact(
      $pb.ServerContext ctx, $3.RemoveContactRequest request);
  $async.Future<$3.SearchUsersResponse> searchUsers(
      $pb.ServerContext ctx, $3.SearchUsersRequest request);
  $async.Future<$3.CreateInviteResponse> createInvite(
      $pb.ServerContext ctx, $3.CreateInviteRequest request);
  $async.Future<$3.ListInvitesResponse> listInvites(
      $pb.ServerContext ctx, $3.ListInvitesRequest request);
  $async.Future<$3.RevokeInviteResponse> revokeInvite(
      $pb.ServerContext ctx, $3.RevokeInviteRequest request);
  $async.Future<$3.PreviewInviteResponse> previewInvite(
      $pb.ServerContext ctx, $3.PreviewInviteRequest request);
  $async.Future<$3.RedeemInviteResponse> redeemInvite(
      $pb.ServerContext ctx, $3.RedeemInviteRequest request);

  $pb.GeneratedMessage createRequest($core.String methodName) {
    switch (methodName) {
      case 'ListContacts':
        return $3.ListContactsRequest();
      case 'AddContact':
        return $3.AddContactRequest();
      case 'RemoveContact':
        return $3.RemoveContactRequest();
      case 'SearchUsers':
        return $3.SearchUsersRequest();
      case 'CreateInvite':
        return $3.CreateInviteRequest();
      case 'ListInvites':
        return $3.ListInvitesRequest();
      case 'RevokeInvite':
        return $3.RevokeInviteRequest();
      case 'PreviewInvite':
        return $3.PreviewInviteRequest();
      case 'RedeemInvite':
        return $3.RedeemInviteRequest();
      default:
        throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $async.Future<$pb.GeneratedMessage> handleCall($pb.ServerContext ctx,
      $core.String methodName, $pb.GeneratedMessage request) {
    switch (methodName) {
      case 'ListContacts':
        return listContacts(ctx, request as $3.ListContactsRequest);
      case 'AddContact':
        return addContact(ctx, request as $3.AddContactRequest);
      case 'RemoveContact':
        return removeContact(ctx, request as $3.RemoveContactRequest);
      case 'SearchUsers':
        return searchUsers(ctx, request as $3.SearchUsersRequest);
      case 'CreateInvite':
        return createInvite(ctx, request as $3.CreateInviteRequest);
      case 'ListInvites':
        return listInvites(ctx, request as $3.ListInvitesRequest);
      case 'RevokeInvite':
        return revokeInvite(ctx, request as $3.RevokeInviteRequest);
      case 'PreviewInvite':
        return previewInvite(ctx, request as $3.PreviewInviteRequest);
      case 'RedeemInvite':
        return redeemInvite(ctx, request as $3.RedeemInviteRequest);
      default:
        throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $core.Map<$core.String, $core.dynamic> get $json => SocialServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
      get $messageJson => SocialServiceBase$messageJson;
}
