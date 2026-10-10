//
//  Generated code. Do not modify.
//  source: ratatosk/v1/chat.proto
//

import "package:connectrpc/connect.dart" as connect;
import "chat.pb.dart" as ratatoskv1chat;
import "chat.connect.spec.dart" as specs;

/// Conversations, messages and the realtime stream.
/// Ordering: every conversation owns a strictly increasing `seq`, assigned by
/// the server on append. Clients paginate and resume by seq, never by time, so
/// a reconnect cannot miss or duplicate a message.
extension type ChatServiceClient (connect.Transport _transport) {
  /// Conversations the caller is a member of, most recently active first.
  Future<ratatoskv1chat.ListConversationsResponse> listConversations(
    ratatoskv1chat.ListConversationsRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.ChatService.listConversations,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// A single conversation, refreshed for the caller.
  Future<ratatoskv1chat.GetConversationResponse> getConversation(
    ratatoskv1chat.GetConversationRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.ChatService.getConversation,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// Reuse or create the 1:1 conversation with another user.
  Future<ratatoskv1chat.CreateDirectConversationResponse> createDirectConversation(
    ratatoskv1chat.CreateDirectConversationRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.ChatService.createDirectConversation,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// Create a group conversation owned by the caller.
  Future<ratatoskv1chat.CreateGroupConversationResponse> createGroupConversation(
    ratatoskv1chat.CreateGroupConversationRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.ChatService.createGroupConversation,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// Rename, re-picture, mute or pin a conversation.
  Future<ratatoskv1chat.UpdateConversationResponse> updateConversation(
    ratatoskv1chat.UpdateConversationRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.ChatService.updateConversation,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// Add users to a group; they see the history from their join point.
  Future<ratatoskv1chat.AddMembersResponse> addMembers(
    ratatoskv1chat.AddMembersRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.ChatService.addMembers,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// Remove a member from a group (owner, or leaving yourself).
  Future<ratatoskv1chat.RemoveMemberResponse> removeMember(
    ratatoskv1chat.RemoveMemberRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.ChatService.removeMember,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// Messages, oldest first, paged by seq in either direction.
  Future<ratatoskv1chat.ListMessagesResponse> listMessages(
    ratatoskv1chat.ListMessagesRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.ChatService.listMessages,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// Append a message. `client_message_id` makes retries idempotent.
  Future<ratatoskv1chat.SendMessageResponse> sendMessage(
    ratatoskv1chat.SendMessageRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.ChatService.sendMessage,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// Rewrite the text of your own message.
  Future<ratatoskv1chat.EditMessageResponse> editMessage(
    ratatoskv1chat.EditMessageRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.ChatService.editMessage,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// Tombstone your own message; attachments are dropped from the store view.
  Future<ratatoskv1chat.DeleteMessageResponse> deleteMessage(
    ratatoskv1chat.DeleteMessageRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.ChatService.deleteMessage,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// Toggle one emoji reaction from the caller.
  Future<ratatoskv1chat.AddReactionResponse> addReaction(
    ratatoskv1chat.AddReactionRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.ChatService.addReaction,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  Future<ratatoskv1chat.RemoveReactionResponse> removeReaction(
    ratatoskv1chat.RemoveReactionRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.ChatService.removeReaction,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// Advance the caller's read cursor, clearing their unread badge.
  Future<ratatoskv1chat.MarkReadResponse> markRead(
    ratatoskv1chat.MarkReadRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.ChatService.markRead,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// Broadcast a typing indicator for a few seconds. Nothing is persisted.
  Future<ratatoskv1chat.SetTypingResponse> setTyping(
    ratatoskv1chat.SetTypingRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.ChatService.setTyping,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// Substring search over the caller's conversations. It can only match
  /// plaintext: end-to-end encrypted message bodies are opaque to the server, so
  /// an encrypted conversation returns nothing here and the client searches
  /// locally instead (docs/E2EE.md).
  Future<ratatoskv1chat.SearchMessagesResponse> searchMessages(
    ratatoskv1chat.SearchMessagesRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.ChatService.searchMessages,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// Upload one file (attachment or profile picture) and get its id back.
  Future<ratatoskv1chat.UploadAttachmentResponse> uploadAttachment(
    ratatoskv1chat.UploadAttachmentRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.ChatService.uploadAttachment,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// Server stream of everything that happens to the caller: new and edited
  /// messages, typing, read cursors, presence, conversation and contact changes.
  Stream<ratatoskv1chat.Event> subscribe(
    ratatoskv1chat.SubscribeRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).server(
      specs.ChatService.subscribe,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }
}
