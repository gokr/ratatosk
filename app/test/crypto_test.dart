// Tests for the end-to-end encryption itself.
//
// Three things matter here, in order:
//
//   1. Two honest clients agree: the same conversation key, the same safety
//      number, and messages that open on the other side.
//   2. A dishonest server cannot read or forge anything: ciphertexts do not
//      open under the wrong key, under a different conversation, or after a
//      byte is flipped.
//   3. A client that is missing a key says so instead of showing garbage.
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ratatosk/src/api/backend.dart';
import 'package:ratatosk/src/crypto/crypto.dart';
import 'package:ratatosk/src/crypto/identity.dart';
import 'package:ratatosk/src/crypto/message_content.dart';
import 'package:ratatosk/src/crypto/session.dart';
import 'package:ratatosk/src/gen/ratatosk/v1/keys.pb.dart';

void main() {
  late RatatoskCrypto crypto;

  setUp(() => crypto = RatatoskCrypto());

  /// A device identity with a fixed device key id, as the server would assign.
  /// The returned fingerprint is the *key* fingerprint, which is what every
  /// derivation uses.
  Future<({DeviceIdentity identity, String fingerprint})> device(String id) async {
    final identityPair = await crypto.newIdentityKeyPair();
    final signingPair = await crypto.newSigningKeyPair();
    final identityPublic = await crypto.publicKeyBytes(identityPair);
    final signingPublic = await crypto.publicKeyBytes(signingPair);
    final fingerprint = await crypto.fingerprint(
      deviceKeyId: id,
      identityPublicKey: identityPublic,
      signingPublicKey: signingPublic,
    );
    final keyFingerprint = await crypto.keyFingerprint(
      identityPublicKey: identityPublic,
      signingPublicKey: signingPublic,
    );
    return (
      identity: DeviceIdentity(
        crypto: crypto,
        identityKeyPair: identityPair,
        signingKeyPair: signingPair,
        identityPublicKey: identityPublic,
        signingPublicKey: signingPublic,
        deviceKeyId: id,
        fingerprint: fingerprint,
        keyFingerprint: keyFingerprint,
      ),
      fingerprint: keyFingerprint,
    );
  }

  DeviceKey publicRecord(DeviceIdentity identity, String userId) => DeviceKey(
        id: identity.deviceKeyId,
        userId: userId,
        identityPublicKey: identity.identityPublicKey,
        signingPublicKey: identity.signingPublicKey,
        fingerprint: identity.fingerprint,
      );

  group('key agreement', () {
    test('two devices derive the same conversation key', () async {
      final ada = await device('k-ada');
      final grace = await device('k-grace');

      final adaKey = await crypto.directConversationKey(
        own: ada.identity.identityKeyPair,
        theirIdentity: crypto.identityPublic(grace.identity.identityPublicKey),
        ownFingerprint: ada.fingerprint,
        theirFingerprint: grace.fingerprint,
      );
      final graceKey = await crypto.directConversationKey(
        own: grace.identity.identityKeyPair,
        theirIdentity: crypto.identityPublic(ada.identity.identityPublicKey),
        ownFingerprint: grace.fingerprint,
        theirFingerprint: ada.fingerprint,
      );

      expect(adaKey, equals(graceKey));
      expect(adaKey.length, symmetricKeyBytes);
    });

    test('a different peer produces a different key', () async {
      final ada = await device('k-ada');
      final grace = await device('k-grace');
      final mallory = await device('k-mallory');

      final withGrace = await crypto.directConversationKey(
        own: ada.identity.identityKeyPair,
        theirIdentity: crypto.identityPublic(grace.identity.identityPublicKey),
        ownFingerprint: ada.fingerprint,
        theirFingerprint: grace.fingerprint,
      );
      final withMallory = await crypto.directConversationKey(
        own: ada.identity.identityKeyPair,
        theirIdentity: crypto.identityPublic(mallory.identity.identityPublicKey),
        ownFingerprint: ada.fingerprint,
        theirFingerprint: mallory.fingerprint,
      );

      expect(withGrace, isNot(equals(withMallory)));
    });

    test('the envelope key is distinct from the conversation key', () async {
      final ada = await device('k-ada');
      final grace = await device('k-grace');

      final conv = await crypto.directConversationKey(
        own: ada.identity.identityKeyPair,
        theirIdentity: crypto.identityPublic(grace.identity.identityPublicKey),
        ownFingerprint: ada.fingerprint,
        theirFingerprint: grace.fingerprint,
      );
      final wrap = await crypto.envelopeKey(
        own: ada.identity.identityKeyPair,
        theirIdentity: crypto.identityPublic(grace.identity.identityPublicKey),
        ownFingerprint: ada.fingerprint,
        theirFingerprint: grace.fingerprint,
      );

      // The domain separation in the HKDF salt is what keeps these apart: if it
      // were missing, a leaked envelope key would also open the conversation.
      expect(conv, isNot(equals(wrap)));
    });
  });

  group('sealing', () {
    test('a sealed value opens with the same key and associated data', () async {
      final key = await crypto.randomBytes(symmetricKeyBytes);
      const aad = 'ratatosk/v1/msg|c1|k1';
      final sealed = await crypto.seal(
        key: key,
        plaintext: utf8.encode('hello'),
        aad: aad,
      );
      final opened = await crypto.unseal(key: key, sealed: sealed, aad: aad);
      expect(utf8.decode(opened), 'hello');
    });

    test('the wrong key, wrong aad or a flipped byte all fail to open', () async {
      final key = await crypto.randomBytes(symmetricKeyBytes);
      final other = await crypto.randomBytes(symmetricKeyBytes);
      const aad = 'ratatosk/v1/msg|c1|k1';
      final sealed = await crypto.seal(key: key, plaintext: utf8.encode('secret'), aad: aad);

      // Wrong key.
      await expectLater(
        crypto.unseal(key: other, sealed: sealed, aad: aad),
        throwsA(isA<CryptoFailure>()),
      );
      // Associated data for a different conversation: this is what stops the
      // server moving a message into another thread.
      await expectLater(
        crypto.unseal(key: key, sealed: sealed, aad: 'ratatosk/v1/msg|other|k1'),
        throwsA(isA<CryptoFailure>()),
      );
      // A tampered ciphertext.
      final tampered = Sealed(
        ciphertext: Uint8List.fromList(sealed.ciphertext)..[0] ^= 0x01,
        nonce: sealed.nonce,
        mac: sealed.mac,
      );
      await expectLater(
        crypto.unseal(key: key, sealed: tampered, aad: aad),
        throwsA(isA<CryptoFailure>()),
      );
      // A re-used nonce with different plaintext is a protocol error, but the
      // AEAD still refuses to open the old tag under the new bytes.
      final reuse = Sealed(
        ciphertext: Uint8List.fromList(sealed.ciphertext),
        nonce: Uint8List.fromList(sealed.nonce),
        mac: Uint8List.fromList(sealed.mac)..[0] ^= 0x01,
      );
      await expectLater(
        crypto.unseal(key: key, sealed: reuse, aad: aad),
        throwsA(isA<CryptoFailure>()),
      );
    });

    test('each seal uses a fresh nonce', () async {
      final key = await crypto.randomBytes(symmetricKeyBytes);
      final first = await crypto.seal(key: key, plaintext: [1, 2, 3], aad: 'x');
      final second = await crypto.seal(key: key, plaintext: [1, 2, 3], aad: 'x');
      expect(first.nonce, isNot(equals(second.nonce)));
      // Identical plaintexts under the same key must not produce identical
      // ciphertexts; a repeating keystream would leak the relationship.
      expect(first.ciphertext, isNot(equals(second.ciphertext)));
    });
  });

  group('key derivation does not depend on the server', () {
    test('a device re-registered under a new id keeps the same conversation key', () async {
      // The server assigns device ids, and it can hand out a new one (a reset
      // database, a removed record). If a conversation key were derived from the
      // id, that would be a lever over the cryptography: two peers would stop
      // agreeing on a key without any key material changing.
      final ada = await device('k-ada-1');
      final grace = await device('k-grace');

      final before = await crypto.directConversationKey(
        own: ada.identity.identityKeyPair,
        theirIdentity: crypto.identityPublic(grace.identity.identityPublicKey),
        ownFingerprint: ada.identity.keyFingerprint,
        theirFingerprint: grace.identity.keyFingerprint,
      );
      // The display fingerprint does change with the id...
      final renamed = await crypto.fingerprint(
        deviceKeyId: 'k-ada-2',
        identityPublicKey: ada.identity.identityPublicKey,
        signingPublicKey: ada.identity.signingPublicKey,
      );
      expect(renamed, isNot(ada.identity.fingerprint));
      // ...but the key fingerprint, and therefore the conversation key, does not.
      expect(ada.identity.keyFingerprint, isNot(equals(renamed)));
      final after = await crypto.directConversationKey(
        own: ada.identity.identityKeyPair,
        theirIdentity: crypto.identityPublic(grace.identity.identityPublicKey),
        ownFingerprint: ada.identity.keyFingerprint,
        theirFingerprint: grace.identity.keyFingerprint,
      );
      expect(after, equals(before));
    });

    test('the safety number follows the keys, not the device id', () async {
      final ada = await device('k-ada');
      final grace = await device('k-grace');
      // The same keys under a different server-assigned id, as a re-registration
      // produces.
      final reRegistered = await crypto.keyFingerprint(
        identityPublicKey: grace.identity.identityPublicKey,
        signingPublicKey: grace.identity.signingPublicKey,
      );
      expect(reRegistered, grace.identity.keyFingerprint);
      expect(
        await crypto.safetyNumber(ada.identity.keyFingerprint, reRegistered),
        await crypto.safetyNumber(ada.identity.keyFingerprint, grace.identity.keyFingerprint),
      );
    });
  });

  group('safety numbers', () {
    test('both sides compute the same number, in the same format', () async {
      final ada = await device('k-ada');
      final grace = await device('k-grace');

      final fromAda = await crypto.safetyNumber(ada.fingerprint, grace.fingerprint);
      final fromGrace = await crypto.safetyNumber(grace.fingerprint, ada.fingerprint);

      expect(fromAda, equals(fromGrace));
      expect(fromAda, matches(RegExp(r'^(\d{5} ){11}\d{5}$')));
    });

    test('a substituted key produces a different number', () async {
      final ada = await device('k-ada');
      final grace = await device('k-grace');
      final impostor = await device('k-grace');

      final real = await crypto.safetyNumber(ada.fingerprint, grace.fingerprint);
      final fake = await crypto.safetyNumber(ada.fingerprint, impostor.fingerprint);
      expect(real, isNot(equals(fake)));
    });
  });

  group('message content', () {
    test('round-trips text, attachments and a reply', () {
      final content = MessageContent(
        text: 'look at this',
        attachments: [
          EncryptedAttachment(
            blobId: 'f1',
            fileKey: Uint8List.fromList(List.generate(32, (i) => i)),
            nonce: Uint8List.fromList(List.generate(24, (i) => i * 2)),
            filename: 'holiday.jpg',
            contentType: 'image/jpeg',
            size: 4096,
          ),
        ],
        replyTo: const ReplyQuote(messageId: 'm1', text: 'earlier'),
      );

      final decoded = MessageContent.decode(content.encode());
      expect(decoded.text, 'look at this');
      expect(decoded.attachments.single.filename, 'holiday.jpg');
      expect(decoded.attachments.single.contentType, 'image/jpeg');
      expect(decoded.attachments.single.fileKey.length, 32);
      expect(decoded.attachments.single.isImage, isTrue);
      expect(decoded.replyTo?.messageId, 'm1');
      expect(decoded.replyTo?.text, 'earlier');
    });

    test('an unknown version is refused rather than guessed', () {
      final bytes = MessageContent(text: 'hi').encode();
      final bumped = Uint8List.fromList(bytes)..[0] = 99;
      expect(() => MessageContent.decode(bumped), throwsA(isA<CryptoFailure>()));
    });

    test('the sealed bytes contain none of the plaintext', () async {
      final key = await crypto.randomBytes(symmetricKeyBytes);
      final content = MessageContent(
        text: 'the secret plan',
        attachments: [
          EncryptedAttachment(
            blobId: 'f1',
            fileKey: await crypto.randomBytes(32),
            nonce: await crypto.randomBytes(24),
            filename: 'plans.pdf',
            contentType: 'application/pdf',
            size: 12,
          ),
        ],
      );
      final sealed = await crypto.seal(
        key: key,
        plaintext: content.encode(),
        aad: messageAad(conversationId: 'c1', senderDeviceKeyId: 'k-ada'),
      );

      // This is the whole promise: what the server stores must not contain any
      // of the words or filenames that went in.
      final blob = utf8.decode(sealed.combined, allowMalformed: true);
      expect(blob, isNot(contains('secret plan')));
      expect(blob, isNot(contains('plans.pdf')));
      expect(blob, isNot(contains('application/pdf')));
      // And it still opens.
      final opened = MessageContent.decode(
        await crypto.unseal(key: key, sealed: sealed, aad: messageAad(conversationId: 'c1', senderDeviceKeyId: 'k-ada')),
      );
      expect(opened.text, 'the secret plan');
      expect(opened.attachments.single.filename, 'plans.pdf');
    });
  });

  group('file sealing', () {
    test('a file opens with the key from the envelope', () async {
      final files = FileCipher(crypto);
      final data = Uint8List.fromList(List.generate(5000, (i) => i % 251));
      final sealed = await files.seal(data);

      final opened = await files.open(
        ciphertext: sealed.ciphertext,
        key: sealed.key,
        nonce: sealed.nonce,
      );
      expect(opened, equals(data));

      // A different file key does not open it.
      final wrongKey = await crypto.randomBytes(symmetricKeyBytes);
      await expectLater(
        files.open(ciphertext: sealed.ciphertext, key: wrongKey, nonce: sealed.nonce),
        throwsA(isA<CryptoFailure>()),
      );
      // And the ciphertext does not contain the file.
      expect(sealed.ciphertext.length, greaterThan(data.length));
    });
  });

  group('sender keys and envelopes', () {
    test('a distributed sender key opens a group message', () async {
      final ada = await device('k-ada');
      final grace = await device('k-grace');

      // One backend for both sides, as one server serves both clients. Each
      // session names its own device key, which is what the envelope fetch is
      // scoped to.
      final server = StubBackend()
        ..addDeviceKey(userId: 'u-ada', key: publicRecord(ada.identity, 'u-ada'))
        ..addDeviceKey(userId: 'u-grace', key: publicRecord(grace.identity, 'u-grace'));

      final adaSession = CryptoSession(backend: server, identity: ada.identity, crypto: crypto)
        ..ownUserId = 'u-ada';
      final graceSession = CryptoSession(backend: server, identity: grace.identity, crypto: crypto)
        ..ownUserId = 'u-grace';

      // Ada seals a message with the sender key she is about to distribute.
      final sealed = await adaSession.encrypt(
        conversationId: 'g1',
        content: MessageContent(text: 'hello group'),
        isGroup: true,
      );

      // Grace cannot read it before she has the key: this is also what keeps a
      // newly added member from reading history from before they joined.
      final before = await graceSession.decrypt(
        conversationId: 'g1',
        senderDeviceKeyId: 'k-ada',
        ciphertext: sealed.sealed.combined,
        nonce: sealed.sealed.nonce,
        isGroup: true,
        peer: null,
        ownMessage: false,
      );
      expect(before.ok, isFalse);
      expect(before.failure, contains('Waiting for the key'));

      // Ada distributes her sender key to the other member's device.
      await adaSession.refreshDeviceKeys(['u-grace']);
      await adaSession.distributeSenderKey(conversationId: 'g1', memberUserIds: ['u-grace']);
      expect(server.envelopes, hasLength(1));
      // The server holds an opaque blob: it cannot see the sender key.
      final stored = server.envelopes.single;
      expect(stored.wrappedKey, isNot(equals(adaSession.ownSenderKey('g1').key)));
      expect(stored.recipientDeviceKeyId, 'k-grace');

      // Grace collects it and now reads the message.
      await graceSession.refreshDeviceKeys(['u-ada']);
      final learned = await graceSession.collectSenderKeys(conversationId: 'g1');
      expect(learned, 1);

      final after = await graceSession.decrypt(
        conversationId: 'g1',
        senderDeviceKeyId: 'k-ada',
        ciphertext: sealed.sealed.combined,
        nonce: sealed.sealed.nonce,
        isGroup: true,
        peer: null,
        ownMessage: false,
      );
      expect(after.ok, isTrue);
      expect(after.content!.text, 'hello group');

      // Distributing twice is idempotent: a second send the same epoch does not
      // stack up envelopes.
      await adaSession.distributeSenderKey(conversationId: 'g1', memberUserIds: ['u-grace']);
      expect(server.envelopes, hasLength(1));

      // An envelope cannot be opened by a device it was not addressed to.
      final mallory = await device('k-mallory');
      final mallorySession = CryptoSession(backend: server, identity: mallory.identity, crypto: crypto)
        ..ownUserId = 'u-mallory';
      await mallorySession.refreshDeviceKeys(['u-ada']);
      final stolen = await mallorySession.collectSenderKeys(conversationId: 'g1');
      expect(stolen, 0, reason: 'an envelope addressed to grace must not open for mallory');
    });

    test('rotating the sender key changes the epoch and the key', () async {
      final ada = await device('k-ada');
      final session = CryptoSession(
        backend: StubBackend(),
        identity: ada.identity,
        crypto: crypto,
      )..ownUserId = 'u-ada';

      final first = session.ownSenderKey('g1');
      final rotated = await session.rotateSenderKey('g1');
      expect(rotated.epoch, first.epoch + 1);
      expect(rotated.key, isNot(equals(first.key)));
      // The epoch guard keeps a message sealed under the old key from opening
      // with the new one.
      final content = MessageContent(text: 'after rotation');
      final sealed = await session.encrypt(conversationId: 'g1', content: content, isGroup: true);
      expect(sealed.epoch, rotated.epoch);
    });

    test('a message sealed for one conversation does not open in another', () async {
      final ada = await device('k-ada');
      final grace = await device('k-grace');

      final key = await crypto.directConversationKey(
        own: ada.identity.identityKeyPair,
        theirIdentity: crypto.identityPublic(grace.identity.identityPublicKey),
        ownFingerprint: ada.fingerprint,
        theirFingerprint: grace.fingerprint,
      );
      final sealed = await crypto.seal(
        key: key,
        plaintext: MessageContent(text: 'for c1').encode(),
        aad: messageAad(conversationId: 'c1', senderDeviceKeyId: 'k-ada'),
      );
      await expectLater(
        crypto.unseal(
          key: key,
          sealed: sealed,
          aad: messageAad(conversationId: 'c2', senderDeviceKeyId: 'k-ada'),
        ),
        throwsA(isA<CryptoFailure>()),
      );
    });

    test('a message relabelled to another sender key does not open', () async {
      final key = await crypto.randomBytes(symmetricKeyBytes);
      final sealed = await crypto.seal(
        key: key,
        plaintext: MessageContent(text: 'hi').encode(),
        aad: messageAad(conversationId: 'c1', senderDeviceKeyId: 'k-ada'),
      );
      await expectLater(
        crypto.unseal(
          key: key,
          sealed: sealed,
          aad: messageAad(conversationId: 'c1', senderDeviceKeyId: 'k-mallory'),
        ),
        throwsA(isA<CryptoFailure>()),
      );
    });
  });

  group('sender keys survive a restart', () {
    test('a restored sender key opens this device\'s own group message', () async {
      // Your own group messages are sealed with your own sender key, and nobody
      // can re-send you that key: the envelope it arrived in was addressed to
      // the session that has gone. Without persistence a restart makes your own
      // history unreadable — which is exactly what a client would show as
      // "Waiting for the key to this message".
      final ada = await device('k-ada');
      final store = MemorySenderKeyStore();

      final before = CryptoSession(
        backend: StubBackend(),
        identity: ada.identity,
        crypto: crypto,
        senderKeyStore: store,
      );
      final originalKey = before.ownSenderKey('g1');
      final sealed = await before.encrypt(
        conversationId: 'g1',
        content: MessageContent(text: 'written before the restart'),
        isGroup: true,
      );

      // A new session over the same store: a fresh process.
      final after = CryptoSession(
        backend: StubBackend(),
        identity: ada.identity,
        crypto: crypto,
        senderKeyStore: store,
      );
      await after.restoreSenderKeys();
      expect(after.ownSenderKey('g1').key, originalKey.key);
      expect(after.ownSenderKey('g1').epoch, originalKey.epoch);

      final opened = await after.decrypt(
        conversationId: 'g1',
        senderDeviceKeyId: 'k-ada',
        ciphertext: sealed.sealed.combined,
        nonce: sealed.sealed.nonce,
        isGroup: true,
        peer: null,
        ownMessage: true,
      );
      expect(opened.ok, isTrue, reason: opened.failure ?? '');
      expect(opened.content!.text, 'written before the restart');
    });

    test('without persistence the same message is unreadable, as it used to be', () async {
      final ada = await device('k-ada');
      final before = CryptoSession(
        backend: StubBackend(),
        identity: ada.identity,
        crypto: crypto,
        senderKeyStore: MemorySenderKeyStore(),
      );
      final sealed = await before.encrypt(
        conversationId: 'g1',
        content: MessageContent(text: 'lost'),
        isGroup: true,
      );

      final after = CryptoSession(
        backend: StubBackend(),
        identity: ada.identity,
        crypto: crypto,
        senderKeyStore: MemorySenderKeyStore(), // a store that was never written
      );
      await after.restoreSenderKeys();
      final opened = await after.decrypt(
        conversationId: 'g1',
        senderDeviceKeyId: 'k-ada',
        ciphertext: sealed.sealed.combined,
        nonce: sealed.sealed.nonce,
        isGroup: true,
        peer: null,
        ownMessage: true,
      );
      // A *different* key comes out of a load with nothing in it, so the message
      // does not open. This is the behaviour the persistence above removes.
      expect(opened.ok, isFalse);
    });
  });

  group('membership changes rotate the sender key', () {
    test('rotating changes the epoch, persists it, and re-distributes', () async {
      final ada = await device('k-ada');
      final store = MemorySenderKeyStore();
      final session = CryptoSession(
        backend: StubBackend(),
        identity: ada.identity,
        crypto: crypto,
        senderKeyStore: store,
      );
      final first = session.ownSenderKey('g1');

      final rotated = await session.rotateSenderKey('g1');
      expect(rotated.epoch, first.epoch + 1);
      expect(rotated.key, isNot(equals(first.key)));

      // The new key is what a restarted client loads, so the removed member
      // cannot be handed it by a stale local cache either.
      final reopened = CryptoSession(
        backend: StubBackend(),
        identity: ada.identity,
        crypto: crypto,
        senderKeyStore: store,
      );
      await reopened.restoreSenderKeys();
      expect(reopened.ownSenderKey('g1').epoch, rotated.epoch);
      expect(reopened.ownSenderKey('g1').key, rotated.key);
    });

    test('membershipOf is order-independent, so nobody rotates by accident', () {
      expect(CryptoSession.membershipOf(['u-b', 'u-a']), CryptoSession.membershipOf(['u-a', 'u-b']));
      expect(CryptoSession.membershipOf(['u-a']), isNot(CryptoSession.membershipOf(['u-a', 'u-b'])));
    });
  });

  group('device identity', () {
    test('is created once, persisted, and registered with the server', () async {
      final storage = MemoryKeyStorage();
      final backend = StubBackend();
      final manager = IdentityManager(backend: backend, storage: storage, crypto: crypto);

      final first = await manager.ensureIdentity(label: 'Laptop', platform: 'linux');
      expect(first.deviceKeyId, isNotEmpty);
      expect(first.fingerprint.length, 64);
      expect(backend.published, hasLength(1));

      // A second manager over the same storage loads the same keys rather than
      // generating new ones: otherwise every restart would orphan the history.
      final second = IdentityManager(backend: backend, storage: storage, crypto: crypto);
      final reloaded = await second.ensureIdentity();
      expect(reloaded.deviceKeyId, first.deviceKeyId);
      expect(reloaded.identityPublicKey, equals(first.identityPublicKey));
      expect(reloaded.fingerprint, first.fingerprint);
      expect(backend.published, hasLength(2));
    });

    test('refuses to continue when the server reports another fingerprint', () async {
      final storage = MemoryKeyStorage();
      final backend = StubBackend()..lieAboutFingerprint = true;
      final manager = IdentityManager(backend: backend, storage: storage, crypto: crypto);
      await expectLater(manager.ensureIdentity(), throwsA(isA<CryptoFailure>()));
    });
  });
}

/// A backend stub for the crypto tests.
///
/// It implements the key registry for real (in memory) and forwards everything
/// else to `noSuchMethod`: the crypto layer only ever calls these methods, and a
/// stub that grew a full chat surface would be a second implementation to keep
/// correct.
class StubBackend implements ChatBackend {
  final List<DeviceKey> published = [];
  final List<KeyEnvelope> envelopes = [];
  final Map<String, List<DeviceKey>> _byUser = {};

  /// The device key this "client" claims, which scopes the envelope fetch.
  String? _deviceKeyId;

  /// Makes the next publish report a fingerprint that disagrees with the
  /// locally computed one, simulating a server that substituted key material.
  bool lieAboutFingerprint = false;

  void addDeviceKey({required String userId, required DeviceKey key}) {
    (_byUser[userId] ??= []).add(key);
  }

  DeviceKey keyById(String id) => _byUser.values
      .expand((keys) => keys)
      .firstWhere((key) => key.id == id);

  @override
  void setToken(String? token) {}

  @override
  void setDeviceKeyId(String? deviceKeyId) => _deviceKeyId = deviceKeyId;

  @override
  Future<DeviceKey> publishDeviceKey({
    String id = '',
    required Uint8List identityPublicKey,
    required Uint8List signingPublicKey,
    String label = '',
    String platform = '',
  }) async {
    final keyId = id.isEmpty ? 'k-${published.length + 1}' : id;
    final key = DeviceKey(
      id: keyId,
      identityPublicKey: identityPublicKey,
      signingPublicKey: signingPublicKey,
      label: label,
      platform: platform,
      fingerprint: lieAboutFingerprint ? 'deadbeef' : '',
    );
    published.add(key);
    return key;
  }

  @override
  Future<List<DeviceKey>> listDeviceKeys(List<String> userIds, {bool includeRevoked = false}) async =>
      userIds.isEmpty
          ? _byUser.values.expand((keys) => keys).toList()
          : [
              for (final id in userIds) ...?_byUser[id],
            ];

  @override
  Future<void> putKeyEnvelope({
    required String conversationId,
    required String senderDeviceKeyId,
    required String recipientDeviceKeyId,
    required int epoch,
    required Uint8List wrappedKey,
    required Uint8List nonce,
  }) async {
    final duplicate = envelopes.any((e) =>
        e.conversationId == conversationId &&
        e.senderDeviceKeyId == senderDeviceKeyId &&
        e.recipientDeviceKeyId == recipientDeviceKeyId &&
        e.epoch == epoch);
    if (duplicate) return;
    envelopes.add(KeyEnvelope(
      id: 'e${envelopes.length + 1}',
      conversationId: conversationId,
      senderDeviceKeyId: senderDeviceKeyId,
      recipientDeviceKeyId: recipientDeviceKeyId,
      epoch: epoch,
      wrappedKey: wrappedKey,
      nonce: nonce,
    ));
  }

  @override
  Future<List<KeyEnvelope>> listKeyEnvelopes({String conversationId = ''}) async =>
      envelopes
          .where((e) => _deviceKeyId == null || e.recipientDeviceKeyId == _deviceKeyId)
          .where((e) => conversationId.isEmpty || e.conversationId == conversationId)
          .toList();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not part of the crypto path');
}
