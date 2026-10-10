//
//  Generated code. Do not modify.
//  source: ratatosk/v1/social.proto
//

import "package:connectrpc/connect.dart" as connect;
import "social.pb.dart" as ratatoskv1social;
import "social.connect.spec.dart" as specs;

/// Contacts, discovery and invitation links.
extension type SocialServiceClient (connect.Transport _transport) {
  /// The caller's contacts, newest first.
  Future<ratatoskv1social.ListContactsResponse> listContacts(
    ratatoskv1social.ListContactsRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.SocialService.listContacts,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// Become contacts with a user by handle, creating the direct conversation.
  Future<ratatoskv1social.AddContactResponse> addContact(
    ratatoskv1social.AddContactRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.SocialService.addContact,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// Drop a contact (history and conversations are kept).
  Future<ratatoskv1social.RemoveContactResponse> removeContact(
    ratatoskv1social.RemoveContactRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.SocialService.removeContact,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// Find people by handle or display name; empty query lists recent users.
  Future<ratatoskv1social.SearchUsersResponse> searchUsers(
    ratatoskv1social.SearchUsersRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.SocialService.searchUsers,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// Mint an invite link that makes two users contacts when redeemed.
  Future<ratatoskv1social.CreateInviteResponse> createInvite(
    ratatoskv1social.CreateInviteRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.SocialService.createInvite,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// Invites the caller created, newest first.
  Future<ratatoskv1social.ListInvitesResponse> listInvites(
    ratatoskv1social.ListInvitesRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.SocialService.listInvites,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// Invalidate an invite link.
  Future<ratatoskv1social.RevokeInviteResponse> revokeInvite(
    ratatoskv1social.RevokeInviteRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.SocialService.revokeInvite,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// Look at an invite without redeeming it. No token required, so the invite
  /// landing page can show who invited you.
  Future<ratatoskv1social.PreviewInviteResponse> previewInvite(
    ratatoskv1social.PreviewInviteRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.SocialService.previewInvite,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// Redeem an invite: both sides become contacts.
  Future<ratatoskv1social.RedeemInviteResponse> redeemInvite(
    ratatoskv1social.RedeemInviteRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.SocialService.redeemInvite,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }
}
