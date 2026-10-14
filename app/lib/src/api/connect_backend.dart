import 'dart:typed_data';

import 'package:connectrpc/connect.dart' as connect_rpc;
import 'package:fixnum/fixnum.dart';

import '../gen/ratatosk/v1/auth.connect.client.dart';
import '../gen/ratatosk/v1/auth.pb.dart';
import '../gen/ratatosk/v1/chat.connect.client.dart';
import '../gen/ratatosk/v1/chat.pb.dart';
import '../gen/ratatosk/v1/common.pb.dart';
import '../gen/ratatosk/v1/keys.connect.client.dart';
import '../gen/ratatosk/v1/keys.pb.dart';
import '../gen/ratatosk/v1/social.connect.client.dart';
import '../gen/ratatosk/v1/social.pb.dart';
import 'backend.dart';
import 'http_client.dart';

/// [ChatBackend] on top of the generated Connect clients.
///
/// This class is the only place that knows about the wire: everything else in
/// the app speaks [ChatBackend].
class ConnectBackend implements ChatBackend {
  ConnectBackend({required this.baseUrl, String? token}) : _token = token {
    auth = AuthServiceClient(_transport);
    chat = ChatServiceClient(_transport);
    social = SocialServiceClient(_transport);
    keys = KeyServiceClient(_transport);
  }

  @override
  final Uri baseUrl;

  String? _token;

  /// `late` so the initializer may call [_bearer]: a plain field initializer
  /// cannot touch instance state, a lazy one gets to.
  late final connect_rpc.Transport _transport = createConnectTransport(
        baseUrl: baseUrl,
        interceptors: [_bearer()],
      );

  late final AuthServiceClient auth;
  late final ChatServiceClient chat;
  late final SocialServiceClient social;
  late final KeyServiceClient keys;

  /// The device key this install holds, sent as a header so the server can
  /// scope the key-envelope calls to it.
  String? _deviceKeyId;

  @override
  void setToken(String? token) => _token = token;

  @override
  void setDeviceKeyId(String? deviceKeyId) => _deviceKeyId = deviceKeyId;

  @override
  String fileUrl(String path) {
    if (path.isEmpty) return '';
    final resolved = baseUrl.resolve(path).toString();
    if (_token == null) return resolved;
    // Attachment bytes are served by plain HTTP GET. A browser <img> cannot
    // attach an Authorization header, so the token rides in the query string;
    // on native clients this is equally harmless and keeps one code path.
    final separator = resolved.contains('?') ? '&' : '?';
    return '$resolved${separator}token=$_token';
  }

  @override
  Future<Uint8List> fetchBytes(String path) async {
    // A plain authenticated GET outside the Connect transport: this is file
    // transfer, not an RPC, and it has to stream bytes rather than a message.
    final client = createConnectHttpClient();
    final headers = connect_rpc.Headers();
    if (_token != null) {
      headers.set('authorization', ['Bearer $_token']);
    }
    final response = await client(connect_rpc.HttpRequest(
      baseUrl.resolve(path).toString(),
      'GET',
      headers,
      null,
      null,
    ));
    if (response.status != 200) {
      throw StateError('could not fetch $path (HTTP ${response.status})');
    }
    final chunks = <int>[];
    await for (final chunk in response.body) {
      chunks.addAll(chunk);
    }
    return Uint8List.fromList(chunks);
  }

  /// One interceptor for every call, unary and streaming alike: this is what
  /// keeps `Subscribe` authenticated too.
  ///
  /// The generic closure is written out longhand because `Interceptor` is a
  /// *generic* function type: a plain lambda would be inferred as
  /// `dynamic`-typed and fail to match the transport.
  connect_rpc.Interceptor _bearer() {
    return <I extends Object, O extends Object>(connect_rpc.AnyFn<I, O> next) {
      return (connect_rpc.Request<I, O> request) async {
        final token = _token;
        if (token != null && token.isNotEmpty) {
          // `set` rather than the `[]=` extension: the extension only resolves
          // when its library is imported without a prefix.
          request.headers.set('authorization', ['Bearer $token']);
        }
        final deviceKeyId = _deviceKeyId;
        if (deviceKeyId != null && deviceKeyId.isNotEmpty) {
          request.headers.set('x-ratatosk-device-key', [deviceKeyId]);
        }
        return next(request);
      };
    };
  }

  @override
  Future<AuthResult> register({
    required String username,
    required String password,
    String displayName = '',
    String inviteCode = '',
  }) async {
    final response = await auth.register(RegisterRequest(
      username: username,
      password: password,
      displayName: displayName,
      inviteCode: inviteCode,
    ));
    return (token: response.token, user: response.user);
  }

  @override
  Future<AuthResult> login({required String username, required String password}) async {
    final response = await auth.login(LoginRequest(username: username, password: password));
    return (token: response.token, user: response.user);
  }

  @override
  Future<void> logout() async {
    await auth.logout(LogoutRequest());
  }

  @override
  Future<AccountDeletion> deleteAccount({required String password}) async {
    final response = await auth.deleteAccount(DeleteAccountRequest(password: password));
    return AccountDeletion(
      conversations: response.conversationsDeleted,
      messages: response.messagesDeleted,
      attachments: response.attachmentsDeleted,
    );
  }

  @override
  Future<GoogleSignInConfig> googleSignInConfig() async {
    final response = await auth.googleSignInConfig(GoogleSignInConfigRequest());
    return GoogleSignInConfig(
      enabled: response.enabled,
      clientId: response.clientId,
      authorizationEndpoint: response.authorizationEndpoint,
      redirectUri: response.redirectUri,
    );
  }

  @override
  Future<AuthResult> finishGoogleSignUp({
    required String pendingToken,
    required String username,
    required String inviteCode,
    String displayName = '',
  }) async {
    final response = await auth.finishGoogleSignUp(FinishGoogleSignUpRequest(
      pendingToken: pendingToken,
      username: username,
      inviteCode: inviteCode,
      displayName: displayName,
    ));
    return (token: response.token, user: response.user);
  }

  @override
  Future<SignInMethods> signInMethods() async {
    final response = await auth.signInMethods(SignInMethodsRequest());
    return SignInMethods(
      methods: response.methods,
      googleEmail: response.googleEmail,
    );
  }

  @override
  Future<String> googleLinkUrl() async {
    final response = await auth.googleLinkUrl(GoogleLinkUrlRequest());
    return response.url;
  }

  @override
  Future<void> unlinkGoogle() async {
    await auth.unlinkGoogle(UnlinkGoogleRequest());
  }

  @override
  Future<void> putKeyBackup(KeyBackupPayload backup) async {
    await keys.putKeyBackup(PutKeyBackupRequest(
      backup: KeyBackup(
        salt: backup.salt,
        nonce: backup.nonce,
        blob: backup.blob,
        kdf: backup.kdf,
        memoryKib: backup.memoryKiB,
        iterations: backup.iterations,
        parallelism: backup.parallelism,
        version: backup.version,
      ),
    ));
  }

  @override
  Future<KeyBackupPayload?> getKeyBackup() async {
    final response = await keys.getKeyBackup(GetKeyBackupRequest());
    if (!response.hasBackup()) return null;
    final b = response.backup;
    return KeyBackupPayload(
      salt: b.salt,
      nonce: b.nonce,
      blob: b.blob,
      kdf: b.kdf,
      memoryKiB: b.memoryKib,
      iterations: b.iterations,
      parallelism: b.parallelism,
      version: b.version,
    );
  }

  @override
  Future<void> deleteKeyBackup() async {
    await keys.deleteKeyBackup(DeleteKeyBackupRequest());
  }

  @override
  Future<User> getMe() async {
    final response = await auth.getMe(GetMeRequest());
    return response.user;
  }

  @override
  Future<User> updateProfile({
    String? displayName,
    String? bio,
    String? avatarAttachmentId,
    String? accentColor,
    bool clearAvatar = false,
  }) async {
    final response = await auth.updateProfile(UpdateProfileRequest(
      displayName: displayName ?? '',
      bio: bio,
      avatarAttachmentId: avatarAttachmentId ?? '',
      accentColor: accentColor ?? '',
      clearAvatar: clearAvatar,
    ));
    return response.user;
  }

  @override
  Future<List<Conversation>> listConversations() async {
    final response = await chat.listConversations(ListConversationsRequest());
    return response.conversations;
  }

  @override
  Future<Conversation> getConversation(String conversationId) async {
    final response = await chat.getConversation(GetConversationRequest(conversationId: conversationId));
    return response.conversation;
  }

  @override
  Future<Conversation> createDirectConversation({String? username, String? userId}) async {
    final response = await chat.createDirectConversation(CreateDirectConversationRequest(
      username: username ?? '',
      userId: userId ?? '',
    ));
    return response.conversation;
  }

  @override
  Future<Conversation> createGroupConversation({
    required String title,
    List<String> usernames = const [],
  }) async {
    final response = await chat.createGroupConversation(CreateGroupConversationRequest(
      title: title,
      usernames: usernames,
    ));
    return response.conversation;
  }

  @override
  Future<Conversation> updateConversation(
    String conversationId, {
    String? title,
    String? avatarAttachmentId,
    bool clearAvatar = false,
    bool? muted,
    bool? pinned,
  }) async {
    final request = UpdateConversationRequest(
      conversationId: conversationId,
      title: title ?? '',
      avatarAttachmentId: avatarAttachmentId ?? '',
      clearAvatar: clearAvatar,
    );
    // Presence of the optional fields is the signal: absent means "leave it".
    if (muted != null) request.muted = muted;
    if (pinned != null) request.pinned = pinned;
    final response = await chat.updateConversation(request);
    return response.conversation;
  }

  @override
  Future<Conversation> addMembers(String conversationId, {List<String> usernames = const []}) async {
    final response = await chat.addMembers(AddMembersRequest(
      conversationId: conversationId,
      usernames: usernames,
    ));
    return response.conversation;
  }

  @override
  Future<Conversation> removeMember(String conversationId, {String? userId}) async {
    final response = await chat.removeMember(RemoveMemberRequest(
      conversationId: conversationId,
      userId: userId ?? '',
    ));
    return response.conversation;
  }

  @override
  Future<MessagePage> listMessages(
    String conversationId, {
    int beforeSeq = 0,
    int afterSeq = 0,
    int limit = 50,
  }) async {
    final response = await chat.listMessages(ListMessagesRequest(
      conversationId: conversationId,
      beforeSeq: Int64(beforeSeq),
      afterSeq: Int64(afterSeq),
      limit: limit,
    ));
    return (messages: response.messages, hasMore: response.hasMore);
  }

  @override
  Future<Message> sendMessage(
    String conversationId, {
    required String text,
    List<String> attachmentIds = const [],
    String? replyToId,
    String? clientMessageId,
  }) async {
    final response = await chat.sendMessage(SendMessageRequest(
      conversationId: conversationId,
      text: text,
      attachmentIds: attachmentIds,
      replyToId: replyToId ?? '',
      clientMessageId: clientMessageId ?? '',
    ));
    return response.message;
  }

  @override
  Future<Message> sendEncryptedMessage(
    String conversationId, {
    required Uint8List ciphertext,
    required Uint8List nonce,
    required String senderDeviceKeyId,
    required int keyEpoch,
    required String cryptoVersion,
    List<String> attachmentIds = const [],
    String? clientMessageId,
  }) async {
    final response = await chat.sendMessage(SendMessageRequest(
      conversationId: conversationId,
      ciphertext: ciphertext,
      nonce: nonce,
      senderDeviceKeyId: senderDeviceKeyId,
      keyEpoch: keyEpoch,
      cryptoVersion: cryptoVersion,
      attachmentIds: attachmentIds,
      clientMessageId: clientMessageId ?? '',
    ));
    return response.message;
  }

  @override
  Future<Message> editEncryptedMessage(
    String messageId, {
    required Uint8List ciphertext,
    required Uint8List nonce,
    required String cryptoVersion,
  }) async {
    final response = await chat.editMessage(EditMessageRequest(
      messageId: messageId,
      ciphertext: ciphertext,
      nonce: nonce,
      cryptoVersion: cryptoVersion,
    ));
    return response.message;
  }

  @override
  Future<Message> editMessage(String messageId, String text) async {
    final response = await chat.editMessage(EditMessageRequest(messageId: messageId, text: text));
    return response.message;
  }

  @override
  Future<Message> deleteMessage(String messageId) async {
    final response = await chat.deleteMessage(DeleteMessageRequest(messageId: messageId));
    return response.message;
  }

  @override
  Future<Message> addReaction(String messageId, String emoji) async {
    final response = await chat.addReaction(AddReactionRequest(messageId: messageId, emoji: emoji));
    return response.message;
  }

  @override
  Future<Message> removeReaction(String messageId, String emoji) async {
    final response = await chat.removeReaction(RemoveReactionRequest(messageId: messageId, emoji: emoji));
    return response.message;
  }

  @override
  Future<int> markRead(String conversationId, {int upToSeq = 0}) async {
    final response = await chat.markRead(MarkReadRequest(
      conversationId: conversationId,
      upToSeq: Int64(upToSeq),
    ));
    return response.lastReadSeq.toInt();
  }

  @override
  Future<void> setTyping(String conversationId, bool typing) async {
    await chat.setTyping(SetTypingRequest(conversationId: conversationId, typing: typing));
  }

  @override
  Future<List<MessageHit>> searchMessages({String query = '', String? conversationId}) async {
    final response = await chat.searchMessages(SearchMessagesRequest(
      query: query,
      conversationId: conversationId ?? '',
    ));
    return response.results
        .map((result) => (
              message: result.message,
              conversationTitle: result.conversationTitle,
              senderName: result.senderName,
              avatarUrl: result.avatarUrl,
            ))
        .toList();
  }

  @override
  Future<Attachment> uploadAttachment({
    required String filename,
    required String contentType,
    required Uint8List data,
    bool encrypted = false,
  }) async {
    final response = await chat.uploadAttachment(UploadAttachmentRequest(
      filename: filename,
      contentType: contentType,
      data: data,
      encrypted: encrypted,
    ));
    return response.attachment;
  }

  // --- end-to-end encryption ---------------------------------------------

  @override
  Future<DeviceKey> publishDeviceKey({
    String id = '',
    required Uint8List identityPublicKey,
    required Uint8List signingPublicKey,
    String label = '',
    String platform = '',
  }) async {
    final response = await keys.publishDeviceKey(PublishDeviceKeyRequest(
      id: id,
      identityPublicKey: identityPublicKey,
      signingPublicKey: signingPublicKey,
      label: label,
      platform: platform,
    ));
    return response.deviceKey;
  }

  @override
  Future<List<DeviceKey>> listDeviceKeys(List<String> userIds, {bool includeRevoked = false}) async {
    final response = await keys.listDeviceKeys(ListDeviceKeysRequest(
      userIds: userIds,
      includeRevoked: includeRevoked,
    ));
    return response.deviceKeys;
  }

  @override
  Future<void> revokeDeviceKey(String id) async {
    await keys.revokeDeviceKey(RevokeDeviceKeyRequest(id: id));
  }

  @override
  Future<void> putKeyEnvelope({
    required String conversationId,
    required String senderDeviceKeyId,
    required String recipientDeviceKeyId,
    required int epoch,
    required Uint8List wrappedKey,
    required Uint8List nonce,
  }) async {
    await keys.putKeyEnvelope(PutKeyEnvelopeRequest(
      conversationId: conversationId,
      senderDeviceKeyId: senderDeviceKeyId,
      recipientDeviceKeyId: recipientDeviceKeyId,
      epoch: epoch,
      wrappedKey: wrappedKey,
      nonce: nonce,
    ));
  }

  @override
  Future<List<KeyEnvelope>> listKeyEnvelopes({String conversationId = ''}) async {
    final response = await keys.listKeyEnvelopes(ListKeyEnvelopesRequest(
      conversationId: conversationId,
    ));
    return response.envelopes;
  }

  @override
  Stream<Event> subscribe() => chat.subscribe(SubscribeRequest());

  @override
  Future<List<Contact>> listContacts() async {
    final response = await social.listContacts(ListContactsRequest());
    return response.contacts;
  }

  @override
  Future<ContactResult> addContact(String username) async {
    final response = await social.addContact(AddContactRequest(username: username));
    return (contact: response.contact, conversation: response.hasConversation() ? response.conversation : null);
  }

  @override
  Future<void> removeContact(String userId) async {
    await social.removeContact(RemoveContactRequest(userId: userId));
  }

  @override
  Future<List<User>> searchUsers(String query) async {
    final response = await social.searchUsers(SearchUsersRequest(query: query));
    return response.users;
  }

  @override
  Future<Invite> createInvite({int expiresInHours = 0, int maxUses = 0}) async {
    final response = await social.createInvite(CreateInviteRequest(
      expiresInHours: expiresInHours,
      maxUses: maxUses,
    ));
    return response.invite;
  }

  @override
  Future<List<Invite>> listInvites() async {
    final response = await social.listInvites(ListInvitesRequest());
    return response.invites;
  }

  @override
  Future<void> revokeInvite(String code) async {
    await social.revokeInvite(RevokeInviteRequest(code: code));
  }

  @override
  Future<InvitePreview> previewInvite(String code) async {
    final response = await social.previewInvite(PreviewInviteRequest(code: code));
    return (
      valid: response.valid,
      reason: response.reason,
      detail: _inviteDetail(response.reason),
      inviter: response.hasInviter() ? response.inviter : null,
      expiresOn: '',
      remainingUses: response.remainingUses,
    );
  }

  @override
  Future<RedeemResult> redeemInvite(String code) async {
    final response = await social.redeemInvite(RedeemInviteRequest(code: code));
    return (inviter: response.inviter, conversation: response.conversation);
  }

  /// The server's machine-readable reason, said in words. Kept in sync with the
  /// server's own copy for the invite landing page.
  static String _inviteDetail(String reason) {
    return switch (reason) {
      'revoked' => 'This invitation was cancelled by the person who sent it.',
      'expired' => 'This invitation has expired.',
      'exhausted' => 'This invitation has already been used.',
      'unknown' => 'We could not find that invitation.',
      _ => 'This invitation is not available.',
    };
  }
}
