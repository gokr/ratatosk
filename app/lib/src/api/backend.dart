import 'dart:typed_data';

import 'package:connectrpc/protocol/connect.dart' as connect;
import 'package:connectrpc/connect.dart' as connect_rpc;
import 'package:connectrpc/protobuf.dart';

import '../gen/ratatosk/v1/chat.pb.dart';
import '../gen/ratatosk/v1/common.pb.dart';
import '../gen/ratatosk/v1/keys.pb.dart';
import '../gen/ratatosk/v1/social.pb.dart';
import 'http_client.dart';

/// The result of a successful sign-in or sign-up.
typedef AuthResult = ({String token, User user});

/// Everything the app's UI needs from the server.
///
/// The UI talks to this interface rather than to the generated clients, for two
/// reasons: the widget tests can drive a whole conversation against an in-memory
/// fake, and the transport (Connect over HTTP, with or without TLS) stays a
/// single implementation detail in `connect_backend.dart`.
///
/// The types crossing this boundary are the generated protobuf messages. They
/// are plain immutable data with no transport attached, so sharing them with
/// the UI costs nothing.
abstract interface class ChatBackend {
  /// The origin this backend talks to, shown in settings and used to resolve
  /// attachment paths.
  Uri get baseUrl;

  /// Replaces the session token used for every subsequent call.
  void setToken(String? token);

  /// Names the device key this install holds, so the server can scope the
  /// key-envelope calls to it. Sent as a header, not as part of the token.
  void setDeviceKeyId(String? deviceKeyId);

  /// A URL the platform can load directly, with the session token appended for
  /// the cases where a plain <img> cannot send an Authorization header.
  String fileUrl(String path);

  /// Fetches attachment bytes through the authenticated transport.
  ///
  /// Needed because the server stores ciphertext for an encrypted conversation:
  /// an image widget cannot open a sealed blob, so the bytes have to be
  /// downloaded and decrypted in the app.
  Future<Uint8List> fetchBytes(String path);

  // --- accounts ----------------------------------------------------------

  Future<AuthResult> register({
    required String username,
    required String password,
    String displayName,
  });

  Future<AuthResult> login({required String username, required String password});

  Future<void> logout();

  Future<User> getMe();

  Future<User> updateProfile({
    String? displayName,
    String? bio,
    String? avatarAttachmentId,
    String? accentColor,
    bool clearAvatar,
  });

  // --- conversations -----------------------------------------------------

  Future<List<Conversation>> listConversations();

  Future<Conversation> getConversation(String conversationId);

  Future<Conversation> createDirectConversation({String? username, String? userId});

  Future<Conversation> createGroupConversation({
    required String title,
    List<String> usernames,
  });

  Future<Conversation> updateConversation(
    String conversationId, {
    String? title,
    String? avatarAttachmentId,
    bool clearAvatar,
    bool? muted,
    bool? pinned,
  });

  Future<Conversation> addMembers(String conversationId, {List<String> usernames});

  Future<Conversation> removeMember(String conversationId, {String? userId});

  // --- messages ----------------------------------------------------------

  /// One page of history. Exactly one of [beforeSeq] / [afterSeq] is normally
  /// set: before for scrolling up, after for catching up.
  Future<MessagePage> listMessages(
    String conversationId, {
    int beforeSeq = 0,
    int afterSeq = 0,
    int limit = 50,
  });

  /// Sends a plaintext message. Only used for a conversation without
  /// encryption; the app's normal path is [sendEncryptedMessage].
  Future<Message> sendMessage(
    String conversationId, {
    required String text,
    List<String> attachmentIds,
    String? replyToId,
    String? clientMessageId,
  });

  /// Sends a sealed message body. The server stores the ciphertext and the
  /// coordinates of the key that opens it, and nothing else.
  Future<Message> sendEncryptedMessage(
    String conversationId, {
    required Uint8List ciphertext,
    required Uint8List nonce,
    required String senderDeviceKeyId,
    required int keyEpoch,
    required String cryptoVersion,
    List<String> attachmentIds,
    String? clientMessageId,
  });

  /// Replaces the body of an existing message with a fresh seal.
  Future<Message> editEncryptedMessage(
    String messageId, {
    required Uint8List ciphertext,
    required Uint8List nonce,
    required String cryptoVersion,
  });

  Future<Message> editMessage(String messageId, String text);

  Future<Message> deleteMessage(String messageId);

  Future<Message> addReaction(String messageId, String emoji);

  Future<Message> removeReaction(String messageId, String emoji);

  Future<int> markRead(String conversationId, {int upToSeq});

  Future<void> setTyping(String conversationId, bool typing);

  Future<List<MessageHit>> searchMessages({String query, String? conversationId});

  Future<Attachment> uploadAttachment({
    required String filename,
    required String contentType,
    required Uint8List data,
    bool encrypted,
  });

  /// The stream of everything that happens to the signed-in user.
  Stream<Event> subscribe();

  // --- social ------------------------------------------------------------

  Future<List<Contact>> listContacts();

  Future<ContactResult> addContact(String username);

  Future<void> removeContact(String userId);

  Future<List<User>> searchUsers(String query);

  Future<Invite> createInvite({int expiresInHours, int maxUses});

  Future<List<Invite>> listInvites();

  Future<void> revokeInvite(String code);

  Future<InvitePreview> previewInvite(String code);

  Future<RedeemResult> redeemInvite(String code);

  // --- end-to-end encryption ---------------------------------------------

  /// Registers this install's public keys, or refreshes an existing record.
  /// An empty [id] registers a new device.
  Future<DeviceKey> publishDeviceKey({
    String id,
    required Uint8List identityPublicKey,
    required Uint8List signingPublicKey,
    String label,
    String platform,
  });

  /// The device keys of the given users. Only contacts and conversation
  /// partners can be asked about, so this cannot enumerate a stranger's devices.
  Future<List<DeviceKey>> listDeviceKeys(List<String> userIds, {bool includeRevoked});

  /// Marks a device key unusable and drops the envelopes addressed to it.
  Future<void> revokeDeviceKey(String id);

  /// Deposits one wrapped sender key for one recipient device.
  Future<void> putKeyEnvelope({
    required String conversationId,
    required String senderDeviceKeyId,
    required String recipientDeviceKeyId,
    required int epoch,
    required Uint8List wrappedKey,
    required Uint8List nonce,
  });

  /// The envelopes addressed to this device, and the keys they carry.
  Future<List<KeyEnvelope>> listKeyEnvelopes({String conversationId});
}

/// One page of messages plus whether older ones exist.
typedef MessagePage = ({List<Message> messages, bool hasMore});

/// A search hit with enough context to render a result row.
typedef MessageHit = ({
  Message message,
  String conversationTitle,
  String senderName,
  String avatarUrl,
});

/// Adding a contact also reaches the conversation it opened.
typedef ContactResult = ({Contact contact, Conversation? conversation});

/// An invite as seen by someone who has not signed in yet.
typedef InvitePreview = ({
  bool valid,
  String reason,
  String detail,
  User? inviter,
  String expiresOn,
  int remainingUses,
});

typedef RedeemResult = ({User inviter, Conversation conversation});

/// Creates a Connect transport for [baseUrl].
///
/// [interceptors] are applied to unary calls and to the streaming Subscribe
/// alike, which is why the bearer token interceptor lives here rather than in
/// each client.
connect_rpc.Transport createConnectTransport({
  required Uri baseUrl,
  required List<connect_rpc.Interceptor> interceptors,
}) {
  return connect.Transport(
    baseUrl: baseUrl.toString(),
    codec: const ProtoCodec(),
    httpClient: createConnectHttpClient(),
    interceptors: interceptors,
  );
}

/// A one-line, human-readable explanation of a failed call.
String describeError(Object error) {
  if (error is connect_rpc.ConnectException) {
    final message = error.message.trim();
    if (message.isNotEmpty) {
      return message;
    }
    return switch (error.code) {
      connect_rpc.Code.unauthenticated => 'Your session has expired. Sign in again.',
      connect_rpc.Code.permissionDenied => 'You are not allowed to do that.',
      connect_rpc.Code.notFound => 'That is no longer there.',
      connect_rpc.Code.unavailable => 'The server is not reachable.',
      connect_rpc.Code.deadlineExceeded => 'The server took too long to answer.',
      _ => 'Something went wrong (${error.code.name}).',
    };
  }
  if (error is FormatException) {
    return 'The server sent something this app could not read.';
  }
  return 'Could not reach the server.';
}

/// Whether a failure means "the session is gone", which the UI answers by
/// returning to the sign-in screen rather than by showing an error.
bool isAuthFailure(Object error) =>
    error is connect_rpc.ConnectException &&
    error.code == connect_rpc.Code.unauthenticated;
