// An in-memory ChatBackend for widget tests.
//
// It implements the same contract as the real client, so a test can drive the
// whole UI — sign in, list conversations, open a thread, send a message — and
// assert on what is rendered, without a server or a network stack. Failures can
// also be injected, which is what makes the "send failed, worth retrying" path
// testable.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart';
import 'package:ratatosk/src/api/backend.dart';
import 'package:ratatosk/src/gen/ratatosk/v1/chat.pb.dart';
import 'package:ratatosk/src/gen/ratatosk/v1/common.pb.dart';
import 'package:ratatosk/src/gen/ratatosk/v1/keys.pb.dart';
import 'package:ratatosk/src/gen/ratatosk/v1/social.pb.dart';

class FakeUser {
  FakeUser(this.id, this.username, this.displayName);

  final String id;
  final String username;
  final String displayName;

  User toProto() => User(
        id: id,
        username: username,
        displayName: displayName,
        accentColor: '#1da1f2',
        presence: Presence.PRESENCE_ONLINE,
      );
}

class FakeBackend implements ChatBackend {
  FakeBackend({Uri? url}) : baseUrl = url ?? Uri.parse('http://fake.test');

  @override
  final Uri baseUrl;

  String? token;

  /// The user `login`/`register` hands back.
  FakeUser signedInAs = FakeUser('u1', 'ada', 'Ada Lovelace');

  /// Conversations, keyed by id.
  final Map<String, Conversation> conversations = {};
  final Map<String, List<Message>> messages = {};

  /// Messages the fake should already have for a conversation.
  int _seq = 0;

  /// Set to make the next sendMessage throw, exercising the failure UI.
  bool failNextSend = false;

  /// Every message body that arrived *in the clear*. A test asserts this stays
  /// empty for an encrypted conversation.
  final List<String> sentPlaintext = [];

  /// Every sealed body that arrived, which is what an encrypted conversation
  /// must produce instead.
  final List<Uint8List> sealedSends = [];

  /// Whether a send is echoed back on the stream, as a real server does.
  bool echoSends = true;

  /// Whether the echo is delivered *before* the send call returns, which is
  /// what the wire does when the broadcast reaches the client first.
  bool echoBeforeReturn = false;

  /// Set to make subscribe() emit an error, exercising the reconnect path.
  bool failSubscribe = false;

  final _events = StreamController<Event>.broadcast();

  @override
  void setToken(String? value) => token = value;

  /// The device key id this client claims, as the real client sends it.
  String? deviceKeyId;

  @override
  void setDeviceKeyId(String? value) => deviceKeyId = value;

  @override
  String fileUrl(String path) => path.isEmpty ? '' : '$baseUrl$path';

  /// Bytes "on the server", keyed by the path the URL names.
  final Map<String, Uint8List> blobs = {};

  @override
  Future<Uint8List> fetchBytes(String path) async =>
      blobs[path] ?? Uint8List.fromList(utf8.encode('stored bytes for $path'));

  // --- helpers used by tests ---------------------------------------------

  /// Creates a conversation with a peer and (optionally) some history.
  Conversation seedConversation({
    String id = 'c1',
    String peerId = 'u2',
    String peerUsername = 'grace',
    String peerName = 'Grace Hopper',
    String kind = 'direct',
    String title = '',
    List<String> history = const [],
  }) {
    final peer = User(
      id: peerId,
      username: peerUsername,
      displayName: peerName,
      accentColor: '#e0245e',
    );
    final conversation = Conversation(
      id: id,
      kind: kind,
      title: title,
      createdAt: _now(),
      updatedAt: _now(),
      lastSeq: Int64(history.length),
      members: [
        Member(user: signedInAs.toProto(), role: kind == 'group' ? 'owner' : 'member'),
        Member(user: peer, role: 'member'),
      ],
    );
    if (kind == 'direct') {
      conversation.peer = peer;
    }
    conversations[id] = conversation;
    messages[id] = [
      for (var i = 0; i < history.length; i++)
        _message(
          id: '$id-m${i + 1}',
          conversationId: id,
          senderId: peerId,
          text: history[i],
          seq: i + 1,
        ),
    ];
    if (history.isNotEmpty) {
      conversation.lastMessage = messages[id]!.last;
    }
    return conversation;
  }

  /// Pushes an event to anyone listening, as the server would.
  void emit(Event event) => _events.add(event);

  /// Appends a message *without* emitting an event, so it can only be found by
  /// asking the server — which is what the catch-up path does.
  Message deliverSilently(String conversationId, Message message) {
    messages[conversationId]!.add(message);
    return message;
  }

  /// Appends a genuinely sealed message: bytes no key in this test can open,
  /// as a message from an unknown device would be.
  Message seedSealedMessage({
    required String conversationId,
    required String senderDeviceKeyId,
    required String text,
  }) {
    final message = _message(
      id: '$conversationId-sealed-${messages[conversationId]!.length + 1}',
      conversationId: conversationId,
      senderId: 'u2',
      text: '',
      seq: messages[conversationId]!.length + 1,
    )
      ..encrypted = true
      ..ciphertext = Uint8List.fromList(List<int>.filled(48, 3))
      ..nonce = Uint8List.fromList(List<int>.filled(24, 4))
      ..senderDeviceKeyId = senderDeviceKeyId
      ..cryptoVersion = 'ratatosk/v1';
    messages[conversationId]!.add(message);
    return message;
  }

  /// Delivers a message from the peer, the way a real server push would.
  Message deliverFromPeer(String conversationId, String text) {
    _seq++;
    final message = _message(
      id: '$conversationId-incoming-$_seq',
      conversationId: conversationId,
      senderId: 'u2',
      text: text,
      seq: messages[conversationId]!.length + 1,
    );
    messages[conversationId]!.add(message);
    final conversation = conversations[conversationId];
    if (conversation != null) {
      conversation.lastMessage = message;
      conversation.lastSeq = message.seq;
    }
    emit(Event(message: MessageEvent(message: message), seq: Int64(_seq)));
    return message;
  }

  void dispose() => _events.close();

  // --- ChatBackend -------------------------------------------------------

  @override
  Future<AuthResult> register({
    required String username,
    required String password,
    String displayName = '',
  }) async {
    signedInAs = FakeUser('u1', username, displayName.isEmpty ? username : displayName);
    return (token: 'fake-token', user: signedInAs.toProto());
  }

  @override
  Future<AuthResult> login({required String username, required String password}) async {
    if (password != 'password123') {
      throw StateError('bad password');
    }
    signedInAs = FakeUser('u1', username, 'Ada Lovelace');
    return (token: 'fake-token', user: signedInAs.toProto());
  }

  @override
  Future<void> logout() async {}

  @override
  Future<User> getMe() async => signedInAs.toProto();

  @override
  Future<User> updateProfile({
    String? displayName,
    String? bio,
    String? avatarAttachmentId,
    String? accentColor,
    bool clearAvatar = false,
  }) async {
    signedInAs = FakeUser(signedInAs.id, signedInAs.username, displayName ?? signedInAs.displayName);
    return signedInAs.toProto();
  }

  @override
  Future<List<Conversation>> listConversations() async => conversations.values.toList();

  @override
  Future<Conversation> getConversation(String conversationId) async =>
      conversations[conversationId]!;

  @override
  Future<Conversation> createDirectConversation({String? username, String? userId}) async =>
      seedConversation(id: 'c-new', peerName: username ?? 'Someone');

  @override
  Future<Conversation> createGroupConversation({
    required String title,
    List<String> usernames = const [],
  }) async =>
      seedConversation(id: 'g1', kind: 'group', title: title, peerName: 'Group member');

  @override
  Future<Conversation> updateConversation(
    String conversationId, {
    String? title,
    String? avatarAttachmentId,
    bool clearAvatar = false,
    bool? muted,
    bool? pinned,
  }) async {
    final conversation = conversations[conversationId]!;
    if (title != null && title.isNotEmpty) conversation.title = title;
    if (muted != null) conversation.muted = muted;
    if (pinned != null) conversation.pinned = pinned;
    return conversation;
  }

  @override
  Future<Conversation> addMembers(String conversationId, {List<String> usernames = const []}) async =>
      conversations[conversationId]!;

  @override
  Future<Conversation> removeMember(String conversationId, {String? userId}) async {
    final conversation = conversations[conversationId]!;
    if (userId == null || userId.isEmpty) {
      conversation.members.removeWhere((m) => m.user.id == signedInAs.id);
    } else {
      conversation.members.removeWhere((m) => m.user.id == userId);
    }
    return conversation;
  }

  @override
  Future<MessagePage> listMessages(
    String conversationId, {
    int beforeSeq = 0,
    int afterSeq = 0,
    int limit = 50,
  }) async {
    final all = messages[conversationId] ?? <Message>[];
    if (afterSeq > 0) {
      return (messages: all.where((m) => m.seq.toInt() > afterSeq).toList(), hasMore: false);
    }
    if (beforeSeq > 0) {
      final older = all.where((m) => m.seq.toInt() < beforeSeq).toList();
      return (messages: older, hasMore: false);
    }
    return (messages: all, hasMore: false);
  }

  @override
  Future<Message> sendMessage(
    String conversationId, {
    required String text,
    List<String> attachmentIds = const [],
    String? replyToId,
    String? clientMessageId,
  }) async {
    if (failNextSend) {
      failNextSend = false;
      throw StateError('network down');
    }
    if (text.isNotEmpty) sentPlaintext.add(text);
    final existing = (messages[conversationId] ?? const <Message>[]).where(
      (m) => clientMessageId != null && clientMessageId.isNotEmpty && m.clientMessageId == clientMessageId,
    );
    if (existing.isNotEmpty) return existing.first;

    final list = messages.putIfAbsent(conversationId, () => []);
    final message = _message(
      id: '$conversationId-m${list.length + 1}',
      conversationId: conversationId,
      senderId: signedInAs.id,
      text: text,
      seq: list.length + 1,
      clientMessageId: clientMessageId ?? '',
      attachmentIds: attachmentIds,
      replyToId: replyToId ?? '',
    );
    list.add(message);
    // A real server pushes the stored message to every member, the sender
    // included, so the sender's own copy arrives twice: once as the send
    // response, once on the stream. Emitting here keeps the fake honest about
    // that race.
    if (echoSends) {
      final event = Event(message: MessageEvent(message: message), seq: Int64(++_seq));
      if (echoBeforeReturn) {
        emit(event);
      } else {
        scheduleMicrotask(() => emit(event));
      }
    }
    final conversation = conversations[conversationId];
    if (conversation != null) {
      conversation.lastMessage = message;
      conversation.lastSeq = message.seq;
      conversation.updatedAt = _now();
      conversation.unreadCount = 0;
    }
    return message;
  }

  @override
  Future<Message> editMessage(String messageId, String text) async {
    final message = _find(messageId);
    message.text = text;
    message.editedAt = _now();
    return message;
  }

  @override
  Future<Message> deleteMessage(String messageId) async {
    final message = _find(messageId);
    message.deleted = true;
    message.text = '';
    return message;
  }

  @override
  Future<Message> addReaction(String messageId, String emoji) async {
    final message = _find(messageId);
    final existing = message.reactions.where((r) => r.emoji == emoji);
    if (existing.isEmpty) {
      message.reactions.add(Reaction(emoji: emoji, userIds: [signedInAs.id]));
    } else if (!existing.first.userIds.contains(signedInAs.id)) {
      existing.first.userIds.add(signedInAs.id);
    }
    return message;
  }

  @override
  Future<Message> removeReaction(String messageId, String emoji) async {
    final message = _find(messageId);
    message.reactions.removeWhere((r) => r.emoji == emoji);
    return message;
  }

  @override
  Future<int> markRead(String conversationId, {int upToSeq = 0}) async {
    final conversation = conversations[conversationId];
    if (conversation != null) conversation.unreadCount = 0;
    return conversation?.lastSeq.toInt() ?? 0;
  }

  @override
  Future<void> setTyping(String conversationId, bool typing) async {
    emit(Event(
      typing: TypingEvent(
        conversationId: conversationId,
        userId: signedInAs.id,
        displayName: signedInAs.displayName,
        typing: typing,
      ),
    ));
  }

  @override
  Future<List<MessageHit>> searchMessages({String query = '', String? conversationId}) async => const [];

  @override
  Future<Attachment> uploadAttachment({
    required String filename,
    required String contentType,
    required Uint8List data,
    bool encrypted = false,
  }) async =>
      Attachment(
        id: 'f${++_attachmentCounter}',
        // A sealed upload keeps neither the name nor the type, exactly as the
        // server does.
        filename: encrypted ? '' : filename,
        contentType: encrypted ? 'application/octet-stream' : contentType,
        size: Int64(data.length),
        url: '/files/f$_attachmentCounter',
        isImage: !encrypted && contentType.startsWith('image/'),
        encrypted: encrypted,
      );

  int _attachmentCounter = 0;

  // --- key registry ------------------------------------------------------

  final Map<String, DeviceKey> deviceKeys = {};
  final List<KeyEnvelope> keyEnvelopes = [];

  @override
  Future<DeviceKey> publishDeviceKey({
    String id = '',
    required Uint8List identityPublicKey,
    required Uint8List signingPublicKey,
    String label = '',
    String platform = '',
  }) async {
    final keyId = id.isEmpty ? 'k${deviceKeys.length + 1}' : id;
    final key = DeviceKey(
      id: keyId,
      userId: signedInAs.id,
      identityPublicKey: identityPublicKey,
      signingPublicKey: signingPublicKey,
      label: label,
      platform: platform,
      createdAt: _now(),
      lastSeen: _now(),
      // Left empty on purpose: the field is a convenience, and a client that
      // recomputes the fingerprint must accept a server that does not send one.
      // (A *disagreeing* fingerprint is a different matter: the client refuses
      // to continue, which crypto_test.dart covers.)
      fingerprint: '',
    );
    deviceKeys[keyId] = key;
    return key;
  }

  /// Registers a device key for somebody else, as a real peer's app would when
  /// it publishes one.
  void addDeviceKey({required String userId, required DeviceKey key}) {
    deviceKeys[key.id] = DeviceKey(
      id: key.id,
      userId: userId,
      identityPublicKey: key.identityPublicKey,
      signingPublicKey: key.signingPublicKey,
      fingerprint: key.fingerprint,
    );
  }

  @override
  Future<List<DeviceKey>> listDeviceKeys(List<String> userIds, {bool includeRevoked = false}) async =>
      deviceKeys.values
          .where((k) => userIds.isEmpty ? k.userId == signedInAs.id : userIds.contains(k.userId))
          .where((k) => includeRevoked || !k.revoked)
          .toList();

  @override
  Future<void> revokeDeviceKey(String id) async {
    final existing = deviceKeys[id];
    if (existing != null) {
      deviceKeys[id] = DeviceKey(
        id: existing.id,
        userId: existing.userId,
        identityPublicKey: existing.identityPublicKey,
        signingPublicKey: existing.signingPublicKey,
        fingerprint: existing.fingerprint,
        revoked: true,
      );
    }
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
    final duplicate = keyEnvelopes.any((e) =>
        e.conversationId == conversationId &&
        e.senderDeviceKeyId == senderDeviceKeyId &&
        e.recipientDeviceKeyId == recipientDeviceKeyId &&
        e.epoch == epoch);
    if (duplicate) return;
    keyEnvelopes.add(KeyEnvelope(
      id: 'e${keyEnvelopes.length + 1}',
      conversationId: conversationId,
      senderDeviceKeyId: senderDeviceKeyId,
      recipientDeviceKeyId: recipientDeviceKeyId,
      epoch: epoch,
      wrappedKey: wrappedKey,
      nonce: nonce,
      createdAt: _now(),
    ));
  }

  @override
  Future<List<KeyEnvelope>> listKeyEnvelopes({String conversationId = ''}) async {
    if (deviceKeyId == null || deviceKeyId!.isEmpty) {
      throw StateError('no device key');
    }
    return keyEnvelopes
        .where((e) => e.recipientDeviceKeyId == deviceKeyId)
        .where((e) => conversationId.isEmpty || e.conversationId == conversationId)
        .toList();
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
    sealedSends.add(ciphertext);
    final stored = await sendMessage(
      conversationId,
      text: '',
      attachmentIds: attachmentIds,
      clientMessageId: clientMessageId,
    );
    return stored
      ..ciphertext = ciphertext
      ..nonce = nonce
      ..senderDeviceKeyId = senderDeviceKeyId
      ..keyEpoch = keyEpoch
      ..cryptoVersion = cryptoVersion
      ..encrypted = true;
  }

  @override
  Future<Message> editEncryptedMessage(
    String messageId, {
    required Uint8List ciphertext,
    required Uint8List nonce,
    required String cryptoVersion,
  }) async {
    final message = _find(messageId);
    message.text = '';
    message.ciphertext = ciphertext;
    message.nonce = nonce;
    message.cryptoVersion = cryptoVersion;
    message.encrypted = true;
    message.editedAt = _now();
    return message;
  }

  @override
  Stream<Event> subscribe() {
    if (failSubscribe) {
      return Stream.error(StateError('stream refused'));
    }
    // The hello frame is what a real server sends first.
    scheduleMicrotask(() => emit(Event(hello: Hello(user: signedInAs.toProto()))));
    return _events.stream;
  }

  @override
  Future<List<Contact>> listContacts() async => const [];

  @override
  Future<ContactResult> addContact(String username) async => (
        contact: Contact(user: User(id: 'u9', username: username, displayName: username)),
        conversation: seedConversation(id: 'c-contact', peerName: username),
      );

  @override
  Future<void> removeContact(String userId) async {}

  @override
  Future<List<User>> searchUsers(String query) async => [
        User(id: 'u2', username: 'grace', displayName: 'Grace Hopper', accentColor: '#e0245e'),
      ];

  @override
  Future<Invite> createInvite({int expiresInHours = 0, int maxUses = 0}) async => Invite(
        code: 'abc123',
        url: '$baseUrl/join/abc123',
        createdAt: _now(),
        maxUses: 1,
        valid: true,
      );

  @override
  Future<List<Invite>> listInvites() async => const [];

  @override
  Future<void> revokeInvite(String code) async {}

  @override
  Future<InvitePreview> previewInvite(String code) async => (
        valid: true,
        reason: '',
        detail: '',
        inviter: User(id: 'u9', username: 'inviter', displayName: 'Inviter'),
        expiresOn: '',
        remainingUses: 1,
      );

  @override
  Future<RedeemResult> redeemInvite(String code) async => (
        inviter: User(id: 'u9', username: 'inviter', displayName: 'Inviter'),
        conversation: seedConversation(id: 'c-joined', peerName: 'Inviter'),
      );

  // --- internals ---------------------------------------------------------

  Message _find(String messageId) {
    for (final list in messages.values) {
      for (final message in list) {
        if (message.id == messageId) return message;
      }
    }
    throw StateError('no such message: $messageId');
  }

  static Message _message({
    required String id,
    required String conversationId,
    required String senderId,
    required String text,
    required int seq,
    String clientMessageId = '',
    List<String> attachmentIds = const [],
    String replyToId = '',
  }) =>
      Message(
        id: id,
        conversationId: conversationId,
        senderId: senderId,
        text: text,
        seq: Int64(seq),
        createdAt: _now(),
        clientMessageId: clientMessageId,
        replyToId: replyToId,
        kind: MessageKind.MESSAGE_KIND_TEXT,
        attachments: [
          // The UI reads full Attachment records, so the fake renders ids in the
          // same shape the server would return.
          for (final attachmentId in attachmentIds)
            Attachment(
              id: attachmentId,
              filename: 'file.bin',
              contentType: 'application/octet-stream',
              url: '/files/$attachmentId',
            ),
        ],
      );

  static Timestamp _now() => Timestamp.fromDateTime(DateTime.now().toUtc());
}
