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
import 'dart:async';
import 'dart:convert';
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

  Map<String, dynamic> toJson() => {'epoch': epoch, 'key': base64Encode(key)};

  static SenderKey? fromJson(Map<String, dynamic> json) {
    final raw = json['key'];
    if (raw is! String) return null;
    try {
      return SenderKey(epoch: (json['epoch'] as num?)?.toInt() ?? 0, key: base64Decode(raw));
    } on FormatException {
      return null;
    }
  }
}

/// Where a device's own sender keys live between runs.
///
/// They are key material — they open every message this device sent in a group —
/// so they belong in the platform keystore beside the identity keys, not in a
/// settings file. Without them, restarting the app makes your own group
/// messages unreadable: nobody can re-send you a key you have forgotten, because
/// the envelope it arrived in was addressed to your old session.
abstract interface class SenderKeyStore {
  /// Every key this device has created, per conversation, oldest or newest first
  /// (order is not part of the contract).
  Future<Map<String, List<SenderKey>>> load();
  Future<void> save(Map<String, List<SenderKey>> keys);
}

/// Keeps sender keys in memory only: tests, and any platform with no keystore.
class MemorySenderKeyStore implements SenderKeyStore {
  Map<String, List<SenderKey>> _keys = {};

  @override
  Future<Map<String, List<SenderKey>>> load() async =>
      {for (final e in _keys.entries) e.key: [...e.value]};

  @override
  Future<void> save(Map<String, List<SenderKey>> keys) async =>
      _keys = {for (final e in keys.entries) e.key: [...e.value]};
}

/// The per-account encryption session.
class CryptoSession {
  CryptoSession({
    required this.backend,
    required this.identity,
    RatatoskCrypto? crypto,
    SenderKeyStore? senderKeyStore,
  })  : crypto = crypto ?? RatatoskCrypto(),
        _senderKeyStore = senderKeyStore ?? MemorySenderKeyStore();

  final ChatBackend backend;
  final DeviceIdentity identity;
  final RatatoskCrypto crypto;
  final SenderKeyStore _senderKeyStore;

  /// Loads this device's sender keys from the previous run.
  ///
  /// Called once at startup, before anything is decrypted, so history that was
  /// written by this device stays readable.
  Future<void> restoreSenderKeys() async {
    try {
      final saved = await _senderKeyStore.load();
      for (final entry in saved.entries) {
        _ownSenderKeys[entry.key] = [...entry.value]
          ..sort((a, b) => b.epoch.compareTo(a.epoch));
      }
    } catch (_) {
      // A corrupt store loses the ability to read one's own old group messages,
      // which is bad but not a reason to refuse to start.
    }
  }

  Future<void> _saveSenderKeys() async {
    try {
      await _senderKeyStore.save({
        for (final entry in _ownSenderKeys.entries) entry.key: [...entry.value],
      });
    } catch (_) {
      // Nothing to do: the key still works for this session.
    }
  }

  /// The membership of a conversation, as a comparable value.
  static String membershipOf(Iterable<String> memberUserIds) {
    final sorted = memberUserIds.toList()..sort();
    return sorted.join(',');
  }

  /// Conversation keys for direct chats, keyed by `peerFingerprint`.
  final Map<String, Uint8List> _directKeys = {};

  /// Sender keys we can read, keyed by `conversationId/senderDeviceKeyId` and
  /// ordered by descending epoch.
  final Map<String, List<SenderKey>> _receivedSenderKeys = {};

  /// Sender keys this device created, keyed by conversation id and ordered by
  /// descending epoch.
  ///
  /// A *history*, not just the current key: rotating replaces the key used for
  /// new messages, but the device's own earlier messages were sealed under the
  /// earlier epoch and nothing else can open them. Keeping only the newest made
  /// a device unable to read its own history after a rotation.
  final Map<String, List<SenderKey>> _ownSenderKeys = {};

  /// Device keys by id, and by user, refreshed on demand.
  final Map<String, DeviceKey> _deviceKeys = {};
  final Map<String, List<DeviceKey>> _deviceKeysByUser = {};

  /// Which devices have already been handed this device's sender key, per
  /// conversation and epoch, so a burst of messages does not repeat the
  /// distribution.
  ///
  /// Per *recipient*, not per conversation: a device that appears later (a
  /// second phone, another browser) has to be given the key too, and a flag that
  /// only remembered "this conversation was done" would never come back to it.
  final Map<String, Set<String>> _distributedTo = {};

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
      // Key fingerprints, not display fingerprints: see RatatoskCrypto.
      ownFingerprint: identity.keyFingerprint,
      theirFingerprint: await _peerKeyFingerprint(peer),
    );
    _directKeys[peer.fingerprint] = key;
    return key;
  }

  // --- group sender keys -------------------------------------------------

  /// This device's sender key for a conversation, created on first use.
  SenderKey ownSenderKey(String conversationId) {
    final existing = _ownSenderKeys[conversationId];
    if (existing != null && existing.isNotEmpty) return existing.first;
    final created = SenderKey(key: _randomKey(), epoch: 0);
    _ownSenderKeys[conversationId] = [created];
    // Persisted so a restart does not orphan this device's own messages. Not
    // awaited: the caller is on the send path, and the write is small.
    unawaited(_saveSenderKeys());
    return created;
  }

  /// This device's sender keys for a conversation, newest epoch first.
  List<SenderKey> ownSenderKeys(String conversationId) =>
      _ownSenderKeys[conversationId] ?? const <SenderKey>[];

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

  /// Rotates this device's sender key to a new epoch.
  ///
  /// Called when a conversation's membership changes. A member who was removed
  /// keeps the keys it already received — no protocol can un-send a message —
  /// but the next epoch is distributed only to the people still in the
  /// conversation, so the removed member cannot read anything new.
  Future<SenderKey> rotateSenderKey(String conversationId) async {
    final current = ownSenderKey(conversationId);
    final next = SenderKey(key: _randomKey(), epoch: current.epoch + 1);
    // The previous key is kept, newest first: messages this device already sent
    // are sealed under it, and dropping it would make them unreadable here and
    // nowhere else recoverable.
    _ownSenderKeys[conversationId] = [
      next,
      ...ownSenderKeys(conversationId),
    ];
    // Every recipient needs the new key, and every old epoch's envelopes are
    // now irrelevant for this conversation.
    _distributedTo.removeWhere((marker, _) => marker.startsWith('$conversationId/'));
    await _saveSenderKeys();
    return next;
  }

  /// Distributes this device's sender key for [conversationId] to every other
  /// member's device, including this account's *other* devices.
  ///
  /// Called before the first message this device sends in a conversation, and
  /// again whenever the conversation is prepared: whichever of the recipients
  /// have not been given this epoch's key get it now, so a device that appeared
  /// after the last distribution is picked up rather than left behind.
  ///
  /// Your own other devices are recipients like any other. A message this device
  /// seals can only be opened with this device's sender key, so a device that is
  /// not given it shows your own group messages as unopenable — and no member
  /// can hand it over on this device's behalf.
  Future<void> distributeSenderKey({
    required String conversationId,
    required Iterable<String> memberUserIds,
  }) async {
    // `recipientKeys` already excludes this device; it must not exclude the rest
    // of this account, which is the whole point (see the doc comment).
    final recipients = recipientKeys(memberUserIds);
    if (recipients.isEmpty) return;

    final senderKey = ownSenderKey(conversationId);
    final marker = '$conversationId/${senderKey.epoch}';
    await _saveSenderKeys();

    final done = _distributedTo.putIfAbsent(marker, () => <String>{});
    final pending = recipients.where((key) => !done.contains(key.id)).toList();
    if (pending.isEmpty) return;

    // One listing for the batch: a false negative only costs a redundant write,
    // because the server deduplicates envelopes.
    final onServer = await _envelopeRecipients(conversationId, senderKey.epoch);

    for (final recipient in pending) {
      if (onServer.contains(recipient.id)) {
        done.add(recipient.id);
        continue;
      }
      final wrapKey = await crypto.envelopeKey(
        own: identity.identityKeyPair,
        theirIdentity: crypto.identityPublic(recipient.identityPublicKey),
        ownFingerprint: identity.keyFingerprint,
        theirFingerprint: await _peerKeyFingerprint(recipient),
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
      done.add(recipient.id);
    }
  }

  /// The devices on the server that already hold this device's sender key for
  /// [conversationId] at [epoch].
  ///
  /// A failed listing returns "none held": that costs one redundant write, which
  /// the server deduplicates, rather than skipping a device that needs the key.
  Future<Set<String>> _envelopeRecipients(String conversationId, int epoch) async {
    try {
      final existing = await backend.listKeyEnvelopes(conversationId: conversationId);
      return existing
          .where((envelope) =>
              envelope.senderDeviceKeyId == identity.deviceKeyId && envelope.epoch == epoch)
          .map((envelope) => envelope.recipientDeviceKeyId)
          .toSet();
    } catch (_) {
      return {};
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
        ownFingerprint: identity.keyFingerprint,
        theirFingerprint: await _peerKeyFingerprint(sender),
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

  /// Every key that might open a message from [senderDeviceKeyId], best
  /// candidate first.
  ///
  /// A message names the epoch it was sealed with, so the matching key is tried
  /// first. The rest are offered as fallbacks: a rotation means several epochs
  /// legitimately exist, and a client that did not record an epoch (or recorded
  /// 0) would otherwise look for a key that never existed under that number.
  List<SenderKey> candidatesFor(
    String conversationId,
    String senderDeviceKeyId, {
    required bool ownMessage,
    int epoch = 0,
  }) {
    final keys = ownMessage && senderDeviceKeyId == identity.deviceKeyId
        ? ownSenderKeys(conversationId)
        : (_receivedSenderKeys['$conversationId/$senderDeviceKeyId'] ?? const <SenderKey>[]);
    if (keys.isEmpty) return const [];
    final ordered = [...keys]..sort((a, b) => b.epoch.compareTo(a.epoch));
    final exact = ordered.where((k) => k.epoch == epoch);
    final rest = ordered.where((k) => k.epoch != epoch);
    return [...exact, ...rest];
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
    int epoch = 0,
  }) async {
    try {
      final aad = messageAad(
        conversationId: conversationId,
        senderDeviceKeyId: senderDeviceKeyId,
      );
      final sealed = Sealed.fromCombined(ciphertext, nonce);

      if (!isGroup) {
        final other = peer;
        if (other == null) {
          return const Opened.failed('This conversation has no key to open it with');
        }
        final clear = await crypto.unseal(key: await directKey(other), sealed: sealed, aad: aad);
        return Opened(MessageContent.decode(clear));
      }

      // A group message can be sealed under any epoch this device has seen: the
      // sender rotates when the membership changes, so several epochs legitimately
      // exist at once. Try the epoch the message names, then the others, rather
      // than assuming the newest — which is what made every message sent before a
      // rotation unreadable.
      final candidates = candidatesFor(
        conversationId,
        senderDeviceKeyId,
        ownMessage: ownMessage,
        epoch: epoch,
      );
      if (candidates.isEmpty) {
        return Opened.failed(
          missingSenderKeyReason(senderDeviceKeyId, ownMessage: ownMessage),
        );
      }
      CryptoFailure? lastFailure;
      for (final candidate in candidates) {
        try {
          final clear = await crypto.unseal(key: candidate.key, sealed: sealed, aad: aad);
          return Opened(MessageContent.decode(clear));
        } on CryptoFailure catch (error) {
          // Wrong epoch for this message: keep looking.
          lastFailure = error;
        }
      }
      return Opened.failed(
        lastFailure?.message ?? 'could not open this message with the key we have',
      );
    } on CryptoFailure catch (error) {
      return Opened.failed(error.message);
    } catch (error) {
      return Opened.failed('This message could not be opened');
    }
  }

  /// A peer's key fingerprint, computed from its public keys (and cached, since
  /// every message needs it).
  Future<String> _peerKeyFingerprint(DeviceKey peer) async {
    final cached = _keyFingerprints[peer.id];
    if (cached != null) return cached;
    final value = await crypto.keyFingerprint(
      identityPublicKey: peer.identityPublicKey,
      signingPublicKey: peer.signingPublicKey,
    );
    _keyFingerprints[peer.id] = value;
    return value;
  }

  final Map<String, String> _keyFingerprints = {};

  /// The peer device key of a direct conversation, from the cache.
  DeviceKey? peerDeviceKey(String peerUserId) {
    final keys = _deviceKeysByUser[peerUserId];
    if (keys == null || keys.isEmpty) return null;
    // The oldest registered device is the one whose key the peer has had
    // longest, so it is the safest default when several exist.
    final sorted = [...keys]..sort((a, b) => a.createdAt.toDateTime().compareTo(b.createdAt.toDateTime()));
    return sorted.first;
  }

  /// Why a group message from [senderDeviceKeyId] cannot be opened here, in
  /// words that do not promise a wait that may never end.
  ///
  /// This device may not have received the sender key yet. A sender that still
  /// holds it can distribute it on its next preparation of the conversation.
  /// Losing the sender does not destroy copies already distributed to other
  /// devices, but a new device cannot recover a key when no usable copy remains.
  /// Name a sibling device instead of promising that simply waiting will help.
  String missingSenderKeyReason(String senderDeviceKeyId, {required bool ownMessage}) {
    final known = _deviceKeys[senderDeviceKeyId];
    // `ownMessage` comes from the caller (the sender's user id equals ours); the
    // device directory is authoritative when it knows the device. Either is
    // enough to say this is one of ours.
    final mine = ownMessage ||
        (known != null && _ownUserId().isNotEmpty && known.userId == _ownUserId());
    if (!mine || senderDeviceKeyId == identity.deviceKeyId) {
      // Somebody else's device: the key may still arrive, and usually does.
      return 'Waiting for the key to this message';
    }
    final label = known == null ? '' : (known.label.isNotEmpty ? known.label : known.platform);
    final from = label.isEmpty ? 'another of your devices' : 'your other device ($label)';
    return "Sent from $from, which never shared this conversation's key with this device";
  }

  String _ownUserId() => _ownUserIdCache ?? '';

  /// Set by the owner of this session once the signed-in user is known.
  String? _ownUserIdCache;
  set ownUserId(String id) => _ownUserIdCache = id;

  /// Forgets cached keys for a conversation, so a rotation is picked up.
  void forgetConversation(String conversationId) {
    _ownSenderKeys.remove(conversationId);
    _distributedTo.removeWhere((marker, _) => marker.startsWith('$conversationId/'));
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
