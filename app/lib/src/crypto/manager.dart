// The encryption layer the app talks to.
//
// It sits between the UI and the [CryptoSession]: it knows how a conversation
// maps to a key shape, caches decrypted message bodies, and hands the UI plain
// data instead of protobuf and ciphertext. Everything above this file deals in
// text, attachments and safety numbers.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import '../api/backend.dart';
import '../gen/ratatosk/v1/chat.pb.dart' as proto;
import '../gen/ratatosk/v1/keys.pb.dart';
import 'crypto.dart';
import 'identity.dart';
import 'message_content.dart';
import 'session.dart';

/// An attachment ready to be shown: the plaintext shape, after the sealed
/// envelope has been opened.
class DecryptedAttachment {
  const DecryptedAttachment({
    required this.blobId,
    required this.filename,
    required this.contentType,
    required this.size,
    required this.fileKey,
    required this.nonce,
  });

  final String blobId;
  final String filename;
  final String contentType;
  final int size;
  final Uint8List fileKey;
  final Uint8List nonce;

  bool get isImage => contentType.startsWith('image/');
}

/// What the UI needs to render one message body.
class DecryptedMessage {
  const DecryptedMessage({
    required this.text,
    this.attachments = const [],
    this.replyToId,
    this.replyToText,
    this.unreadable,
  });

  final String text;
  final List<DecryptedAttachment> attachments;
  final String? replyToId;
  final String? replyToText;

  /// Set when the body could not be opened (no key yet, tampered, or a newer
  /// format). The message is then shown as unreadable rather than as empty.
  final String? unreadable;

  bool get ok => unreadable == null;
}

/// The app's encryption façade.
class CryptoManager {
  CryptoManager({
    required this.backend,
    RatatoskCrypto? crypto,
    PrivateKeyStorage? storage,
  })  : crypto = crypto ?? RatatoskCrypto(),
        _storage = storage ?? MemoryKeyStorage();

  final ChatBackend backend;
  final RatatoskCrypto crypto;
  final PrivateKeyStorage _storage;
  late final FileCipher _files = FileCipher(crypto);

  IdentityManager? _identity;
  CryptoSession? _session;
  String? _userId;

  /// Decrypted bodies, keyed by message id. Public: the UI reads it.
  final Map<String, DecryptedMessage> _decrypted = {};

  /// Conversations whose sender keys we have already collected.
  final Set<String> _collected = {};

  DeviceIdentity? get identity => _identity?.current;
  CryptoSession? get session => _session;

  /// Whether this install can encrypt at all. False until identity setup
  /// finished, which is what the UI gates on.
  bool get ready => _session != null;

  /// This device's display fingerprint: the id and keys together, shown when
  /// listing the devices of a conversation.
  String get ownFingerprint => _identity?.current?.fingerprint ?? '';

  /// Whether the server had to be told about this device again because it had
  /// no record of it. Keys are unchanged; nothing needs re-verifying.
  bool get reregistered => _identity?.reregistered ?? false;

  String get ownDeviceKeyId => _identity?.current?.deviceKeyId ?? '';

  /// Creates or loads this install's keys and registers them with the server.
  Future<void> initialize({required String userId, String label = '', String platform = ''}) async {
    _userId = userId;
    _identity = IdentityManager(backend: backend, storage: _storage, crypto: crypto);
    final device = await _identity!.ensureIdentity(label: label, platform: platform);
    backend.setDeviceKeyId(device.deviceKeyId);
    _session = CryptoSession(backend: backend, identity: device, crypto: crypto)..ownUserId = userId;
    await _session!.refreshDeviceKeys([userId]);
  }

  /// Forgets this install's keys and every cached decryption.
  Future<void> forget() async {
    await _identity?.forget();
    _decrypted.clear();
    _collected.clear();
    _session = null;
    backend.setDeviceKeyId(null);
  }

  /// The device key a direct conversation is encrypted to.
  ///
  /// Never this device's own key: a conversation object rendered for the *other*
  /// side carries the reader as `peer`, and deriving a key with ourselves would
  /// silently produce a conversation nobody else can open.
  DeviceKey? peerKeyFor(proto.Conversation conversation) {
    final session = _session;
    if (session == null) return null;

    // Prefer the member list: it is the same on both sides, whereas `peer` is
    // viewer-specific.
    for (final member in conversation.members) {
      if (member.user.id == _userId) continue;
      final key = session.peerDeviceKey(member.user.id);
      if (key != null) return key;
    }
    if (conversation.hasPeer() && conversation.peer.id != _userId) {
      return session.peerDeviceKey(conversation.peer.id);
    }
    return null;
  }

  /// Makes sure the sender keys for a conversation are available.
  ///
  /// Called when a conversation is opened: it refreshes the member device keys,
  /// collects any envelopes addressed to this device, and distributes this
  /// device's sender key when the conversation is a group.
  Future<void> prepareConversation(proto.Conversation conversation) async {
    final session = _session;
    if (session == null) return;
    final memberIds = conversation.members.map((m) => m.user.id).toList();
    await session.refreshDeviceKeys(memberIds);

    final isGroup = conversation.kind == 'group';
    if (isGroup && !_collected.contains(conversation.id)) {
      await session.collectSenderKeys(conversationId: conversation.id);
      _collected.add(conversation.id);
    }
    if (isGroup) {
      // Distributing before the first send means a recipient never has to ask.
      await session.distributeSenderKey(
        conversationId: conversation.id,
        memberUserIds: memberIds,
      );
    }
  }

  /// Re-reads the key envelopes, in case a message arrived before its key did.
  Future<int> collectKeys(proto.Conversation conversation) async {
    final session = _session;
    if (session == null) return 0;
    await session.refreshDeviceKeys(conversation.members.map((m) => m.user.id).toList());
    return session.collectSenderKeys(conversationId: conversation.id);
  }

  /// Whether this device can seal a message for this conversation.
  ///
  /// False when encryption is not set up at all, and for a direct conversation
  /// whose peer has published no device key — a script client, or somebody who
  /// has not opened an app yet. The UI reports that state instead of claiming
  /// the conversation is encrypted, and the send path refuses rather than
  /// quietly falling back to plaintext.
  bool canEncrypt(proto.Conversation conversation) {
    if (!ready) return false;
    if (conversation.kind == 'group') return true;
    return peerKeyFor(conversation) != null;
  }

  /// The peer whose device key is missing, for the message that says so.
  String? peerWithoutKey(proto.Conversation conversation) {
    if (!ready || conversation.kind == 'group' || peerKeyFor(conversation) != null) return null;
    if (conversation.hasPeer()) return conversation.peer.displayName;
    for (final member in conversation.members) {
      if (member.user.id != _userId) return member.user.displayName;
    }
    return null;
  }

  /// Seals a message body and returns what to put on the wire.
  Future<({Uint8List ciphertext, Uint8List nonce, int epoch, String deviceKeyId})> sealMessage({
    required proto.Conversation conversation,
    required MessageContent content,
  }) async {
    final session = _session;
    if (session == null) {
      throw CryptoFailure('this device has no encryption keys yet');
    }
    final isGroup = conversation.kind == 'group';
    if (!isGroup && peerKeyFor(conversation) == null) {
      final who = peerWithoutKey(conversation) ?? 'this contact';
      throw CryptoFailure(
        '$who has not set up encryption yet, so there is no key to seal this message with. '
        'They need to sign in with the app at least once.',
      );
    }
    final sealed = await session.encrypt(
      conversationId: conversation.id,
      content: content,
      isGroup: isGroup,
      peer: isGroup ? null : peerKeyFor(conversation),
    );
    return (
      ciphertext: sealed.sealed.combined,
      nonce: sealed.sealed.nonce,
      epoch: sealed.epoch,
      deviceKeyId: session.device.deviceKeyId,
    );
  }

  /// Opens a stored message, caching the result.
  Future<DecryptedMessage> decryptMessage({
    required proto.Conversation conversation,
    required proto.Message message,
    required bool ownMessage,
  }) async {
    final cached = _decrypted[message.id];
    if (cached != null) return cached;

    final session = _session;
    if (session == null) {
      return const DecryptedMessage(text: '', unreadable: 'Encryption is not set up on this device yet');
    }
    if (!message.encrypted) {
      // A system note, or a message from before encryption. Still readable.
      final plain = DecryptedMessage(
        text: message.deleted ? '' : message.text,
        replyToId: message.replyToId.isEmpty ? null : message.replyToId,
        replyToText: message.hasReplyTo() ? message.replyTo.text : null,
        attachments: message.attachments
            .map((a) => DecryptedAttachment(
                  blobId: a.id,
                  filename: a.filename,
                  contentType: a.contentType,
                  size: a.size.toInt(),
                  fileKey: Uint8List(0),
                  nonce: Uint8List(0),
                ))
            .toList(),
      );
      _decrypted[message.id] = plain;
      return plain;
    }

    final isGroup = conversation.kind == 'group';
    final opened = await session.decrypt(
      conversationId: conversation.id,
      senderDeviceKeyId: message.senderDeviceKeyId,
      ciphertext: message.ciphertext,
      nonce: message.nonce,
      isGroup: isGroup,
      peer: isGroup ? null : peerKeyFor(conversation),
      ownMessage: ownMessage,
    );

    final DecryptedMessage result;
    if (!opened.ok) {
      result = DecryptedMessage(text: '', unreadable: opened.failure);
    } else {
      final body = opened.content!;
      result = DecryptedMessage(
        text: body.text,
        attachments: body.attachments
            .map((a) => DecryptedAttachment(
                  blobId: a.blobId,
                  filename: a.filename,
                  contentType: a.contentType,
                  size: a.size,
                  fileKey: a.fileKey,
                  nonce: a.nonce,
                ))
            .toList(),
        replyToId: body.replyTo?.messageId,
        replyToText: body.replyTo?.text,
      );
    }
    // An unreadable message is not cached: its key may still arrive.
    if (result.ok) _decrypted[message.id] = result;
    return result;
  }

  /// The cached body of a message, if it has been opened.
  DecryptedMessage? cached(proto.Message message) =>
      message.encrypted ? _decrypted[message.id] : null;

  /// The body to display, opening it on demand.
  DecryptedMessage display(proto.Message message, proto.Conversation conversation, bool own) =>
      _decrypted[message.id] ??
      DecryptedMessage(
        text: message.deleted ? '' : message.text,
        unreadable: message.encrypted ? 'Opening…' : null,
      );

  /// Seals a file for upload.
  Future<({Uint8List ciphertext, Uint8List key, Uint8List nonce})> sealFile(Uint8List data) =>
      _files.seal(data);

  /// Decrypts attachment bytes fetched from the server.
  Future<Uint8List> openFile({
    required Uint8List ciphertext,
    required DecryptedAttachment attachment,
  }) =>
      _files.open(ciphertext: ciphertext, key: attachment.fileKey, nonce: attachment.nonce);

  /// The safety number for a peer device: the value two users compare out of
  /// band to rule out a substituted key.
  ///
  /// Digests the key fingerprints, so it changes when key material changes and
  /// not when the server hands out a new device id.
  Future<String> safetyNumberFor(DeviceKey peer) async {
    final own = identity?.keyFingerprint;
    if (own == null) throw CryptoFailure('this device has no keys yet');
    final theirs = await crypto.keyFingerprint(
      identityPublicKey: peer.identityPublicKey,
      signingPublicKey: peer.signingPublicKey,
    );
    return crypto.safetyNumber(own, theirs);
  }

  /// Signs a payload with this device's Ed25519 key.
  ///
  /// Used for the key-transparency work in docs/E2EE.md §9; today it proves the
  /// signing key is usable and lets a future version authenticate a key history.
  Future<String> sign(Uint8List payload) async {
    final identity = _identity?.current;
    if (identity == null) throw CryptoFailure('this device has no keys yet');
    final signature = await crypto.signWith(identity.signingKeyPair, payload);
    return base64Encode(signature);
  }
}
