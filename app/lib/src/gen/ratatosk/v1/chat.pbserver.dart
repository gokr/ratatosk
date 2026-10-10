// This is a generated file - do not edit.
//
// Generated from ratatosk/v1/chat.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'chat.pb.dart' as $2;
import 'chat.pbjson.dart';

export 'chat.pb.dart';

abstract class ChatServiceBase extends $pb.GeneratedService {
  $async.Future<$2.ListConversationsResponse> listConversations(
      $pb.ServerContext ctx, $2.ListConversationsRequest request);
  $async.Future<$2.GetConversationResponse> getConversation(
      $pb.ServerContext ctx, $2.GetConversationRequest request);
  $async.Future<$2.CreateDirectConversationResponse> createDirectConversation(
      $pb.ServerContext ctx, $2.CreateDirectConversationRequest request);
  $async.Future<$2.CreateGroupConversationResponse> createGroupConversation(
      $pb.ServerContext ctx, $2.CreateGroupConversationRequest request);
  $async.Future<$2.UpdateConversationResponse> updateConversation(
      $pb.ServerContext ctx, $2.UpdateConversationRequest request);
  $async.Future<$2.AddMembersResponse> addMembers(
      $pb.ServerContext ctx, $2.AddMembersRequest request);
  $async.Future<$2.RemoveMemberResponse> removeMember(
      $pb.ServerContext ctx, $2.RemoveMemberRequest request);
  $async.Future<$2.ListMessagesResponse> listMessages(
      $pb.ServerContext ctx, $2.ListMessagesRequest request);
  $async.Future<$2.SendMessageResponse> sendMessage(
      $pb.ServerContext ctx, $2.SendMessageRequest request);
  $async.Future<$2.EditMessageResponse> editMessage(
      $pb.ServerContext ctx, $2.EditMessageRequest request);
  $async.Future<$2.DeleteMessageResponse> deleteMessage(
      $pb.ServerContext ctx, $2.DeleteMessageRequest request);
  $async.Future<$2.AddReactionResponse> addReaction(
      $pb.ServerContext ctx, $2.AddReactionRequest request);
  $async.Future<$2.RemoveReactionResponse> removeReaction(
      $pb.ServerContext ctx, $2.RemoveReactionRequest request);
  $async.Future<$2.MarkReadResponse> markRead(
      $pb.ServerContext ctx, $2.MarkReadRequest request);
  $async.Future<$2.SetTypingResponse> setTyping(
      $pb.ServerContext ctx, $2.SetTypingRequest request);
  $async.Future<$2.SearchMessagesResponse> searchMessages(
      $pb.ServerContext ctx, $2.SearchMessagesRequest request);
  $async.Future<$2.UploadAttachmentResponse> uploadAttachment(
      $pb.ServerContext ctx, $2.UploadAttachmentRequest request);
  $async.Future<$2.Event> subscribe(
      $pb.ServerContext ctx, $2.SubscribeRequest request);

  $pb.GeneratedMessage createRequest($core.String methodName) {
    switch (methodName) {
      case 'ListConversations':
        return $2.ListConversationsRequest();
      case 'GetConversation':
        return $2.GetConversationRequest();
      case 'CreateDirectConversation':
        return $2.CreateDirectConversationRequest();
      case 'CreateGroupConversation':
        return $2.CreateGroupConversationRequest();
      case 'UpdateConversation':
        return $2.UpdateConversationRequest();
      case 'AddMembers':
        return $2.AddMembersRequest();
      case 'RemoveMember':
        return $2.RemoveMemberRequest();
      case 'ListMessages':
        return $2.ListMessagesRequest();
      case 'SendMessage':
        return $2.SendMessageRequest();
      case 'EditMessage':
        return $2.EditMessageRequest();
      case 'DeleteMessage':
        return $2.DeleteMessageRequest();
      case 'AddReaction':
        return $2.AddReactionRequest();
      case 'RemoveReaction':
        return $2.RemoveReactionRequest();
      case 'MarkRead':
        return $2.MarkReadRequest();
      case 'SetTyping':
        return $2.SetTypingRequest();
      case 'SearchMessages':
        return $2.SearchMessagesRequest();
      case 'UploadAttachment':
        return $2.UploadAttachmentRequest();
      case 'Subscribe':
        return $2.SubscribeRequest();
      default:
        throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $async.Future<$pb.GeneratedMessage> handleCall($pb.ServerContext ctx,
      $core.String methodName, $pb.GeneratedMessage request) {
    switch (methodName) {
      case 'ListConversations':
        return listConversations(ctx, request as $2.ListConversationsRequest);
      case 'GetConversation':
        return getConversation(ctx, request as $2.GetConversationRequest);
      case 'CreateDirectConversation':
        return createDirectConversation(
            ctx, request as $2.CreateDirectConversationRequest);
      case 'CreateGroupConversation':
        return createGroupConversation(
            ctx, request as $2.CreateGroupConversationRequest);
      case 'UpdateConversation':
        return updateConversation(ctx, request as $2.UpdateConversationRequest);
      case 'AddMembers':
        return addMembers(ctx, request as $2.AddMembersRequest);
      case 'RemoveMember':
        return removeMember(ctx, request as $2.RemoveMemberRequest);
      case 'ListMessages':
        return listMessages(ctx, request as $2.ListMessagesRequest);
      case 'SendMessage':
        return sendMessage(ctx, request as $2.SendMessageRequest);
      case 'EditMessage':
        return editMessage(ctx, request as $2.EditMessageRequest);
      case 'DeleteMessage':
        return deleteMessage(ctx, request as $2.DeleteMessageRequest);
      case 'AddReaction':
        return addReaction(ctx, request as $2.AddReactionRequest);
      case 'RemoveReaction':
        return removeReaction(ctx, request as $2.RemoveReactionRequest);
      case 'MarkRead':
        return markRead(ctx, request as $2.MarkReadRequest);
      case 'SetTyping':
        return setTyping(ctx, request as $2.SetTypingRequest);
      case 'SearchMessages':
        return searchMessages(ctx, request as $2.SearchMessagesRequest);
      case 'UploadAttachment':
        return uploadAttachment(ctx, request as $2.UploadAttachmentRequest);
      case 'Subscribe':
        return subscribe(ctx, request as $2.SubscribeRequest);
      default:
        throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $core.Map<$core.String, $core.dynamic> get $json => ChatServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
      get $messageJson => ChatServiceBase$messageJson;
}
