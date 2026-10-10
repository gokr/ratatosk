//
//  Generated code. Do not modify.
//  source: ratatosk/v1/social.proto
//

import "package:connectrpc/connect.dart" as connect;
import "social.pb.dart" as ratatoskv1social;

/// Contacts, discovery and invitation links.
abstract final class SocialService {
  /// Fully-qualified name of the SocialService service.
  static const name = 'ratatosk.v1.SocialService';

  /// The caller's contacts, newest first.
  static const listContacts = connect.Spec(
    '/$name/ListContacts',
    connect.StreamType.unary,
    ratatoskv1social.ListContactsRequest.new,
    ratatoskv1social.ListContactsResponse.new,
  );

  /// Become contacts with a user by handle, creating the direct conversation.
  static const addContact = connect.Spec(
    '/$name/AddContact',
    connect.StreamType.unary,
    ratatoskv1social.AddContactRequest.new,
    ratatoskv1social.AddContactResponse.new,
  );

  /// Drop a contact (history and conversations are kept).
  static const removeContact = connect.Spec(
    '/$name/RemoveContact',
    connect.StreamType.unary,
    ratatoskv1social.RemoveContactRequest.new,
    ratatoskv1social.RemoveContactResponse.new,
  );

  /// Find people by handle or display name; empty query lists recent users.
  static const searchUsers = connect.Spec(
    '/$name/SearchUsers',
    connect.StreamType.unary,
    ratatoskv1social.SearchUsersRequest.new,
    ratatoskv1social.SearchUsersResponse.new,
  );

  /// Mint an invite link that makes two users contacts when redeemed.
  static const createInvite = connect.Spec(
    '/$name/CreateInvite',
    connect.StreamType.unary,
    ratatoskv1social.CreateInviteRequest.new,
    ratatoskv1social.CreateInviteResponse.new,
  );

  /// Invites the caller created, newest first.
  static const listInvites = connect.Spec(
    '/$name/ListInvites',
    connect.StreamType.unary,
    ratatoskv1social.ListInvitesRequest.new,
    ratatoskv1social.ListInvitesResponse.new,
  );

  /// Invalidate an invite link.
  static const revokeInvite = connect.Spec(
    '/$name/RevokeInvite',
    connect.StreamType.unary,
    ratatoskv1social.RevokeInviteRequest.new,
    ratatoskv1social.RevokeInviteResponse.new,
  );

  /// Look at an invite without redeeming it. No token required, so the invite
  /// landing page can show who invited you.
  static const previewInvite = connect.Spec(
    '/$name/PreviewInvite',
    connect.StreamType.unary,
    ratatoskv1social.PreviewInviteRequest.new,
    ratatoskv1social.PreviewInviteResponse.new,
  );

  /// Redeem an invite: both sides become contacts.
  static const redeemInvite = connect.Spec(
    '/$name/RedeemInvite',
    connect.StreamType.unary,
    ratatoskv1social.RedeemInviteRequest.new,
    ratatoskv1social.RedeemInviteResponse.new,
  );
}
