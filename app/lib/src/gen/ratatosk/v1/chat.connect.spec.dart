//
//  Generated code. Do not modify.
//  source: ratatosk/v1/chat.proto
//

import "package:connectrpc/connect.dart" as connect;
import "chat.pb.dart" as ratatoskv1chat;

/// Conversations, messages and the realtime stream.
/// Ordering: every conversation owns a strictly increasing `seq`, assigned by
/// the server on append. Clients paginate and resume by seq, never by time, so
/// a reconnect cannot miss or duplicate a message.
abstract final class ChatService {
  /// Fully-qualified name of the ChatService service.
  static const name = 'ratatosk.v1.ChatService';

  /// Conversations the caller is a member of, most recently active first.
  static const listConversations = connect.Spec(
    '/$name/ListConversations',
    connect.StreamType.unary,
    ratatoskv1chat.ListConversationsRequest.new,
    ratatoskv1chat.ListConversationsResponse.new,
  );

  /// A single conversation, refreshed for the caller.
  static const getConversation = connect.Spec(
    '/$name/GetConversation',
    connect.StreamType.unary,
    ratatoskv1chat.GetConversationRequest.new,
    ratatoskv1chat.GetConversationResponse.new,
  );

  /// Reuse or create the 1:1 conversation with another user.
  static const createDirectConversation = connect.Spec(
    '/$name/CreateDirectConversation',
    connect.StreamType.unary,
    ratatoskv1chat.CreateDirectConversationRequest.new,
    ratatoskv1chat.CreateDirectConversationResponse.new,
  );

  /// Create a group conversation owned by the caller.
  static const createGroupConversation = connect.Spec(
    '/$name/CreateGroupConversation',
    connect.StreamType.unary,
    ratatoskv1chat.CreateGroupConversationRequest.new,
    ratatoskv1chat.CreateGroupConversationResponse.new,
  );

  /// Rename, re-picture, mute or pin a conversation.
  static const updateConversation = connect.Spec(
    '/$name/UpdateConversation',
    connect.StreamType.unary,
    ratatoskv1chat.UpdateConversationRequest.new,
    ratatoskv1chat.UpdateConversationResponse.new,
  );

  /// Add users to a group; they see the history from their join point.
  static const addMembers = connect.Spec(
    '/$name/AddMembers',
    connect.StreamType.unary,
    ratatoskv1chat.AddMembersRequest.new,
    ratatoskv1chat.AddMembersResponse.new,
  );

  /// Remove a member from a group (owner, or leaving yourself).
  static const removeMember = connect.Spec(
    '/$name/RemoveMember',
    connect.StreamType.unary,
    ratatoskv1chat.RemoveMemberRequest.new,
    ratatoskv1chat.RemoveMemberResponse.new,
  );

  /// Messages, oldest first, paged by seq in either direction.
  static const listMessages = connect.Spec(
    '/$name/ListMessages',
    connect.StreamType.unary,
    ratatoskv1chat.ListMessagesRequest.new,
    ratatoskv1chat.ListMessagesResponse.new,
  );

  /// Append a message. `client_message_id` makes retries idempotent.
  static const sendMessage = connect.Spec(
    '/$name/SendMessage',
    connect.StreamType.unary,
    ratatoskv1chat.SendMessageRequest.new,
    ratatoskv1chat.SendMessageResponse.new,
  );

  /// Rewrite the text of your own message.
  static const editMessage = connect.Spec(
    '/$name/EditMessage',
    connect.StreamType.unary,
    ratatoskv1chat.EditMessageRequest.new,
    ratatoskv1chat.EditMessageResponse.new,
  );

  /// Tombstone your own message; attachments are dropped from the store view.
  static const deleteMessage = connect.Spec(
    '/$name/DeleteMessage',
    connect.StreamType.unary,
    ratatoskv1chat.DeleteMessageRequest.new,
    ratatoskv1chat.DeleteMessageResponse.new,
  );

  /// Toggle one emoji reaction from the caller.
  static const addReaction = connect.Spec(
    '/$name/AddReaction',
    connect.StreamType.unary,
    ratatoskv1chat.AddReactionRequest.new,
    ratatoskv1chat.AddReactionResponse.new,
  );

  static const removeReaction = connect.Spec(
    '/$name/RemoveReaction',
    connect.StreamType.unary,
    ratatoskv1chat.RemoveReactionRequest.new,
    ratatoskv1chat.RemoveReactionResponse.new,
  );

  /// Advance the caller's read cursor, clearing their unread badge.
  static const markRead = connect.Spec(
    '/$name/MarkRead',
    connect.StreamType.unary,
    ratatoskv1chat.MarkReadRequest.new,
    ratatoskv1chat.MarkReadResponse.new,
  );

  /// Broadcast a typing indicator for a few seconds. Nothing is persisted.
  static const setTyping = connect.Spec(
    '/$name/SetTyping',
    connect.StreamType.unary,
    ratatoskv1chat.SetTypingRequest.new,
    ratatoskv1chat.SetTypingResponse.new,
  );

  /// Full-text substring search over the caller's conversations.
  static const searchMessages = connect.Spec(
    '/$name/SearchMessages',
    connect.StreamType.unary,
    ratatoskv1chat.SearchMessagesRequest.new,
    ratatoskv1chat.SearchMessagesResponse.new,
  );

  /// Upload one file (attachment or profile picture) and get its id back.
  static const uploadAttachment = connect.Spec(
    '/$name/UploadAttachment',
    connect.StreamType.unary,
    ratatoskv1chat.UploadAttachmentRequest.new,
    ratatoskv1chat.UploadAttachmentResponse.new,
  );

  /// Server stream of everything that happens to the caller: new and edited
  /// messages, typing, read cursors, presence, conversation and contact changes.
  static const subscribe = connect.Spec(
    '/$name/Subscribe',
    connect.StreamType.server,
    ratatoskv1chat.SubscribeRequest.new,
    ratatoskv1chat.Event.new,
  );
}
