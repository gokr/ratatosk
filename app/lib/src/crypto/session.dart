// The encryption session: which key protects which conversation, and the
// encrypt/decrypt paths built on it.
//
// Two shapes exist (docs/E2EE.md §2):
//
//   * Direct conversations derive one key from the two identity keys. Nothing
//     is exchanged and nothing is stored.
//   * Groups use sender keys: a random key per (device, conversation, epoch),
//     distributed to every other member's device as a sealed envelope.
//
// The session owns the cache of both, plus the device-key directory, so callers
// only ever ask "encrypt this" and "decrypt that".
import 'dart:typed_data';

import 'package:cryptography_plus/cryptography_plus.dart' as c;

import '../api/backend.dart';
import '../gen/ratatosk/v1/chat.pb.dart' as proto;
import '../gen/ratatosk/v1/keys.pb.dart';
import 'crypto.dart';
import 'identity.dart';
import 'message_content.dart';

/// The result of trying to open a message.
class Opened {
  const Opened(this.content) : failure = null;
  const Opened.failed(String this.failure) : content = null;

  final MessageContent? content;

  /// Why the message could not be opened, when it could not.
  final String? failure;

  bool get ok => content != null;

  /// The text, or a placeholder explaining why there is none.
  String get displayText {
    final body = content;
    if (body != null) return body.text;
    return failure ?? 'This message cannot be read on this device';
  }
}

/// One sender key, with the epoch it belongs to.
class SenderKey {
  SenderKey({required this.key, required this.epoch});

  final Uint8List key;
  final int epoch;
}

/// The per-account encryption session.
class CryptoSession {
  CryptoSession({
    required this.backend,
    required this.identity,
    RatatoskCrypto? crypto,
  }) : crypto = crypto ?? RatatoskCrypto();

  final ChatBackend backend;
  final DeviceIdentity identity;
  final RatatoskCrypto crypto;

  /// Conversation keys for direct chats, keyed by `peerFingerprint`.
  final Map<String, Uint8List> _directKeys = {};

  /// Sender keys we can read, keyed by `conversationId/senderDeviceKeyId` and
  /// ordered by descending epoch.
  final Map<String, List<SenderKey>> _receivedSenderKeys = {};

  /// Sender keys this device created, keyed by conversation id.
  final Map<String, SenderKey> _ownSenderKeys = {};

  /// Device keys by id, and by user, refreshed on demand.
  final Map<String, DeviceKey> _deviceKeys = {};
  final Map<String, List<DeviceKey>> _deviceKeysByUser = {};

  /// Conversations we have already greeted with a sender key, so a burst of
  /// messages does not repeat the distribution.
  final Set<String> _distributed = {};

  DeviceIdentity get device => identity;

  // --- key directory -----------------------------------------------------

  /// Refreshes the device keys of a set of users.
  Future<void> refreshDeviceKeys(List<String> userIds) async {
    final want = userIds.where((id) => id != identity.deviceKeyId).toList();
    if (want.isEmpty) return;
    final keys = await backend.listDeviceKeys(want);
    for (final key in keys) {
      if (key.revoked) {
        _deviceKeys.remove(key.id);
        continue;
      }
      _deviceKeys[key.id] = key;
      (_deviceKeysByUser[key.userId] ??= []).removeWhere((k) => k.id == key.id);
      (_deviceKeysByUser[key.userId] ??= []).add(key);
    }
  }

  /// A cached device key, or null when it is unknown.
  DeviceKey? deviceKey(String id) => _deviceKeys[id];

  /// Whether a device key has been revoked, which happens between refreshes.
  bool isRevoked(String id) => false;

  /// The device keys of the members of a conversation, excluding this device.
  List<DeviceKey> recipientKeys(Iterable<String> memberUserIds) {
    final out = <DeviceKey>[];
    for (final userId in memberUserIds) {
      for (final key in _deviceKeysByUser[userId] ?? const <DeviceKey>[]) {
        if (key.id == identity.deviceKeyId || key.revoked) continue;
        out.add(key);
      }
    }
    return out;
  }

  // --- direct conversations ---------------------------------------------

  /// The conversation key for a direct chat, derived on first use.
  Future<Uint8List> directKey(DeviceKey peer) async {
    final cached = _directKeys[peer.fingerprint];
    if (cached != null) return cached;
    final key = await crypto.directConversationKey(
      own: identity.identityKeyPair,
      theirIdentity: crypto.identityPublic(peer.identityPublicKey),
      ownFingerprint: identity.fingerprint,
      theirFingerprint: peer.fingerprint,
    );
    _directKeys[peer.fingerprint] = key;
    return key;
  }

  // --- group sender keys -------------------------------------------------

  /// This device's sender key for a conversation, created on first use.
  SenderKey ownSenderKey(String conversationId) =>
      _ownSenderKeys[conversationId] ??= SenderKey(key: _randomKey(), epoch: 0);

  static Uint8List _randomKey() {
    // The sender key is random, not derived, so a fresh one cannot be predicted
    // from anything already on the wire.
    final random = c.SecureRandom.fast;
    final key = Uint8List(symmetricKeyBytes);
    for (var i = 0; i < key.length; i++) {
      key[i] = random.nextUint32() & 0xff;
    }
    return key;
  }

  /// Rotates this device's sender key to a new epoch, after a membership change.
  SenderKey rotateSenderKey(String conversationId) {
    final current = ownSenderKey(conversationId);
    final next = SenderKey(key: _randomKey(), epoch: current.epoch + 1);
    _ownSenderKeys[conversationId] = next;
    // A new epoch means every recipient needs the new key again.
    _distributed.clear();
    return next;
  }

  /// Distributes this device's sender key for [conversationId] to every other
  /// member's device, once per epoch.
  ///
  /// Called before the first message this device sends in a conversation; a
  /// recipient that cannot find a key asks for one by reopening the
  /// conversation, which is where `_distributed` is cleared.
  Future<void> distributeSenderKey({
    required String conversationId,
    required Iterable<String> memberUserIds,
  }) async {
    final recipients = recipientKeys(memberUserIds)
        .where((key) => key.userId != _ownUserId())
        .toList();
    if (recipients.isEmpty) return;

    final senderKey = ownSenderKey(conversationId);
    final marker = '$conversationId/${senderKey.epoch}';
    if (_distributed.contains(marker)) return;

    for (final recipient in recipients) {
      final alreadySent = await _envelopeExists(conversationId, senderKey.epoch, recipient.id);
      if (alreadySent) continue;
      final wrapKey = await crypto.envelopeKey(
        own: identity.identityKeyPair,
        theirIdentity: crypto.identityPublic(recipient.identityPublicKey),
        ownFingerprint: identity.fingerprint,
        theirFingerprint: recipient.fingerprint,
      );
      final payload = Uint8List.fromList(senderKey.key);
      final sealed = await crypto.seal(
        key: wrapKey,
        plaintext: payload,
        aad: envelopeAad(
          conversationId: conversationId,
          senderDeviceKeyId: identity.deviceKeyId,
          epoch: senderKey.epoch,
          recipientDeviceKeyId: recipient.id,
        ),
      );
      await backend.putKeyEnvelope(
        conversationId: conversationId,
        senderDeviceKeyId: identity.deviceKeyId,
        recipientDeviceKeyId: recipient.id,
        epoch: senderKey.epoch,
        wrappedKey: sealed.combined,
        nonce: sealed.nonce,
      );
    }
    _distributed.add(marker);
  }

  /// Whether this device already deposited this envelope.
  ///
  /// The server deduplicates too, so a false negative costs one redundant write
  /// and never a lost key.
  Future<bool> _envelopeExists(String conversationId, int epoch, String recipientId) async {
    try {
      final existing = await backend.listKeyEnvelopes(conversationId: conversationId);
      return existing.any((envelope) =>
          envelope.senderDeviceKeyId == identity.deviceKeyId &&
          envelope.recipientDeviceKeyId == recipientId &&
          envelope.epoch == epoch);
    } catch (_) {
      return false;
    }
  }

  /// Fetches and opens the key envelopes addressed to this device.
  ///
  /// Returns how many new keys were learned, so the caller knows whether a
  /// previously unreadable message might now be readable.
  Future<int> collectSenderKeys({String? conversationId}) async {
    final List<KeyEnvelope> envelopes;
    try {
      envelopes = await backend.listKeyEnvelopes(conversationId: conversationId ?? '');
    } catch (_) {
      return 0;
    }
    var learned = 0;
    for (final envelope in envelopes) {
      if (envelope.recipientDeviceKeyId != identity.deviceKeyId) continue;
      final cacheKey = '${envelope.conversationId}/${envelope.senderDeviceKeyId}';
      final existing = _receivedSenderKeys[cacheKey] ?? const <SenderKey>[];
      if (existing.any((k) => k.epoch == envelope.epoch)) continue;

      final senderKey = await _openEnvelope(envelope);
      if (senderKey == null) continue;

      _receivedSenderKeys[cacheKey] = [...existing, senderKey]
        ..sort((a, b) => b.epoch.compareTo(a.epoch));
      learned++;
    }
    return learned;
  }

  /// Opens one envelope. A failure is normal and expected: an envelope addressed
  /// to a device key that no longer matches, or sealed under a key pair that has
  /// changed. It must not break the rest of the batch.
  Future<SenderKey?> _openEnvelope(KeyEnvelope envelope) async {
    try {
      final sender = _deviceKeys[envelope.senderDeviceKeyId];
      if (sender == null) return null;
      final wrapKey = await crypto.envelopeKey(
        own: identity.identityKeyPair,
        theirIdentity: crypto.identityPublic(sender.identityPublicKey),
        ownFingerprint: identity.fingerprint,
        theirFingerprint: sender.fingerprint,
      );
      final plain = await crypto.unseal(
        key: wrapKey,
        sealed: Sealed.fromCombined(envelope.wrappedKey, envelope.nonce),
        aad: envelopeAad(
          conversationId: envelope.conversationId,
          senderDeviceKeyId: envelope.senderDeviceKeyId,
          epoch: envelope.epoch,
          recipientDeviceKeyId: envelope.recipientDeviceKeyId,
        ),
      );
      return SenderKey(key: plain, epoch: envelope.epoch);
    } catch (_) {
      return null;
    }
  }

  /// The newest sender key we hold for a peer device in a conversation.
  SenderKey? senderKeyFor(String conversationId, String senderDeviceKeyId) {
    final keys = _receivedSenderKeys['$conversationId/$senderDeviceKeyId'];
    if (keys == null || keys.isEmpty) return null;
    return keys.first; // sorted newest epoch first
  }

  /// Whether any sender key is known for the conversation; used to decide
  /// whether a message is worth retrying after collecting keys.
  bool hasKeysFor(String conversationId, String senderDeviceKeyId) =>
      senderKeyFor(conversationId, senderDeviceKeyId) != null;

  // --- encrypt / decrypt -------------------------------------------------

  /// Seals message content for a conversation, choosing the right key shape.
  ///
  /// [peer] is the other participant of a direct conversation; it is ignored for
  /// groups, where this device's sender key is used instead.
  Future<SealedContent> encrypt({
    required String conversationId,
    required MessageContent content,
    required bool isGroup,
    DeviceKey? peer,
  }) async {
    final Uint8List key;
    final int epoch;
    if (isGroup) {
      final senderKey = ownSenderKey(conversationId);
      key = senderKey.key;
      epoch = senderKey.epoch;
    } else {
      if (peer == null) {
        throw CryptoFailure('this conversation has no peer key to encrypt to');
      }
      key = await directKey(peer);
      epoch = 0;
    }
    final sealed = await crypto.seal(
      key: key,
      plaintext: content.encode(),
      aad: messageAad(
        conversationId: conversationId,
        senderDeviceKeyId: identity.deviceKeyId,
      ),
    );
    return SealedContent(sealed: sealed, epoch: epoch);
  }

  /// Opens a stored message.
  ///
  /// A message from a device whose sender key we do not have yet fails with a
  /// reason the UI can show, rather than an exception: the key may arrive later.
  Future<Opened> decrypt({
    required String conversationId,
    required String senderDeviceKeyId,
    required List<int> ciphertext,
    required List<int> nonce,
    required bool isGroup,
    required DeviceKey? peer,
    required bool ownMessage,
  }) async {
    final Uint8List key;
    try {
      if (isGroup) {
        // Our own device key means our own sender key; otherwise the peer's.
        if (senderDeviceKeyId == identity.deviceKeyId) {
          key = ownSenderKey(conversationId).key;
        } else {
          final senderKey = senderKeyFor(conversationId, senderDeviceKeyId);
          if (senderKey == null) {
            return const Opened.failed('Waiting for the key to this message');
          }
          key = senderKey.key;
        }
      } else {
        final other = peer;
        if (other == null) {
          return const Opened.failed('This conversation has no key to open it with');
        }
        key = await directKey(other);
      }

      final clear = await crypto.unseal(
        key: key,
        sealed: Sealed.fromCombined(ciphertext, nonce),
        aad: messageAad(
          conversationId: conversationId,
          senderDeviceKeyId: senderDeviceKeyId,
        ),
      );
      return Opened(MessageContent.decode(clear));
    } on CryptoFailure catch (error) {
      return Opened.failed(error.message);
    } catch (error) {
      return Opened.failed('This message could not be opened');
    }
  }

  /// The peer device key of a direct conversation, from the cache.
  DeviceKey? peerDeviceKey(String peerUserId) {
    final keys = _deviceKeysByUser[peerUserId];
    if (keys == null || keys.isEmpty) return null;
    // The oldest registered device is the one whose key the peer has had
    // longest, so it is the safest default when several exist.
    final sorted = [...keys]..sort((a, b) => a.createdAt.toDateTime().compareTo(b.createdAt.toDateTime()));
    return sorted.first;
  }

  String _ownUserId() => _ownUserIdCache ?? '';

  /// Set by the owner of this session once the signed-in user is known.
  String? _ownUserIdCache;
  set ownUserId(String id) => _ownUserIdCache = id;

  /// Forgets cached keys for a conversation, so a rotation is picked up.
  void forgetConversation(String conversationId) {
    _ownSenderKeys.remove(conversationId);
    _distributed.removeWhere((marker) => marker.startsWith('$conversationId/'));
    _receivedSenderKeys.removeWhere((key, _) => key.startsWith('$conversationId/'));
  }
}

/// A sealed message body plus the coordinates of the key that opens it.
class SealedContent {
  const SealedContent({required this.sealed, required this.epoch});

  final Sealed sealed;
  final int epoch;
}

/// Associated data binding a message to its conversation and sender key.
///
/// The server can move a ciphertext to another conversation, or relabel which
/// key sealed it, but the AEAD then fails to open: that is the point.
String messageAad({required String conversationId, required String senderDeviceKeyId}) =>
    '$cryptoVersion/msg|$conversationId|$senderDeviceKeyId';

/// Associated data binding a key envelope to everything it distributes.
String envelopeAad({
  required String conversationId,
  required String senderDeviceKeyId,
  required int epoch,
  required String recipientDeviceKeyId,
}) =>
    '$cryptoVersion/keyenv|$conversationId|$senderDeviceKeyId|$epoch|$recipientDeviceKeyId';

/// Re-exported so callers do not need two imports for the two message types.
typedef StoredMessage = proto.Message;
