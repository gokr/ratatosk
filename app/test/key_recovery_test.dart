import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ratatosk/src/api/backend.dart';
import 'package:ratatosk/src/crypto/identity.dart';
import 'package:ratatosk/src/crypto/manager.dart';
import 'package:ratatosk/src/crypto/recovery.dart';

import 'fake_backend.dart';

/// Key recovery is the answer to "I reinstalled and cannot read my messages". The
/// test that matters is the whole journey: back the keys up, wipe the device the way
/// a reinstall does, restore on a "new" device, and end up with the *same* identity —
/// because an identity that merely exists is not enough, it has to be the one the
/// old messages were sealed to.
void main() {
  late FakeBackend backend;

  setUp(() => backend = FakeBackend());
  tearDown(() => backend.dispose());

  /// A device with its own storage, as an install has.
  Future<({MemoryKeyStorage storage, CryptoManager manager, String userId})>
      makeDevice(String userId) async {
    final storage = MemoryKeyStorage();
    final manager = CryptoManager(backend: backend, storage: storage);
    await manager.initialize(userId: userId, label: 'phone', platform: 'test');
    return (storage: storage, manager: manager, userId: userId);
  }

  test('a wiped device recovers the same identity', () async {
    final phone = await makeDevice('u1');
    final before = {
      IdentityManager.identityKeySlot:
          await phone.storage.read(IdentityManager.identityKeySlot),
      IdentityManager.signingKeySlot:
          await phone.storage.read(IdentityManager.signingKeySlot),
      IdentityManager.deviceIdSlot:
          await phone.storage.read(IdentityManager.deviceIdSlot),
    };
    expect(before[IdentityManager.identityKeySlot], isNotNull);

    // Turn recovery on.
    final recovery = KeyRecovery(backend: backend, storage: phone.storage);
    await recovery.save('correct horse battery staple');
    expect(backend.keyBackup, isNotNull,
        reason: 'nothing was uploaded, so a reinstall would still lose the keys');

    // The server holds something it cannot read.
    final stored = backend.keyBackup!;
    expect(utf8.decode(stored.blob, allowMalformed: true),
        isNot(contains(before[IdentityManager.identityKeySlot]!)),
        reason: 'the private key is readable in the uploaded blob');

    // Reinstall: a brand-new, empty device.
    final fresh = MemoryKeyStorage();
    final freshRecovery = KeyRecovery(backend: backend, storage: fresh);
    expect(await freshRecovery.hasBackup(), isTrue);
    final restored = await freshRecovery.restore('correct horse battery staple');

    // The identity is byte-identical, which is what makes old messages readable.
    expect(restored, contains(IdentityManager.identityKeySlot));
    expect(await fresh.read(IdentityManager.identityKeySlot),
        before[IdentityManager.identityKeySlot]);
    expect(await fresh.read(IdentityManager.signingKeySlot),
        before[IdentityManager.signingKeySlot]);
    expect(await fresh.read(IdentityManager.deviceIdSlot),
        before[IdentityManager.deviceIdSlot]);

    // And a manager on that storage loads the *same* keys rather than generating
    // new ones — the end-to-end point of the exercise.
    final revived = CryptoManager(backend: backend, storage: fresh);
    await revived.initialize(userId: 'u1', label: 'new phone');
    expect(base64Encode(revived.identity!.identityPublicKey),
        base64Encode(phone.manager.identity!.identityPublicKey),
        reason: 'the restored device ended up with a different identity, so it '
            'still could not open the history it was restored for');
  });

  test('the sender keys travel too, or old messages stay unreadable', () async {
    // The identity alone is not enough for messages this device *sent*: those are
    // sealed under its own sender key. A backup that missed that slot would restore
    // an identity that could not open its own history.
    final phone = await makeDevice('u1');
    await phone.storage.write(senderKeysSlot, jsonEncode({'c1': []}));
    final recovery = KeyRecovery(backend: backend, storage: phone.storage);
    await recovery.save('a passphrase for the test');

    final fresh = MemoryKeyStorage();
    await KeyRecovery(backend: backend, storage: fresh).restore('a passphrase for the test');
    expect(await fresh.read(senderKeysSlot), isNotNull);
  });

  test('the wrong passphrase fails cleanly and changes nothing', () async {
    final phone = await makeDevice('u1');
    await KeyRecovery(backend: backend, storage: phone.storage).save('the right one');

    final fresh = MemoryKeyStorage();
    final recovery = KeyRecovery(backend: backend, storage: fresh);
    await expectLater(
      recovery.restore('the wrong one'),
      throwsA(isA<WrongPassphrase>()),
      reason: 'a wrong passphrase must be reported as such, not as a crash',
    );
    // Nothing half-written: a partial restore would leave a device that looks
    // configured but cannot open anything.
    expect(await fresh.read(IdentityManager.identityKeySlot), isNull);
  });

  test('an account with no backup says so rather than failing obscurely', () async {
    final recovery = KeyRecovery(backend: backend, storage: MemoryKeyStorage());
    expect(await recovery.hasBackup(), isFalse);
    await expectLater(recovery.restore('anything'), throwsA(isA<StateError>()));
  });

  test('a later save replaces the earlier backup', () async {
    // Rotating the passphrase must retire the old one: otherwise a passphrase the
    // user just abandoned still opens their keys.
    final phone = await makeDevice('u1');
    final recovery = KeyRecovery(backend: backend, storage: phone.storage);
    await recovery.save('the first passphrase');
    await recovery.save('the second passphrase');

    final fresh = MemoryKeyStorage();
    final freshRecovery = KeyRecovery(backend: backend, storage: fresh);
    await expectLater(freshRecovery.restore('the first passphrase'),
        throwsA(isA<WrongPassphrase>()));
    await freshRecovery.restore('the second passphrase');
    expect(await fresh.read(IdentityManager.identityKeySlot), isNotNull);
  });

  test('a short passphrase is refused before anything is uploaded', () async {
    final phone = await makeDevice('u1');
    final recovery = KeyRecovery(backend: backend, storage: phone.storage);
    await expectLater(recovery.save('short'), throwsA(isA<ArgumentError>()));
    expect(backend.keyBackup, isNull);
  });

  test('the KDF parameters come from the backup, not this build', () async {
    // A backup written when the work factor was lower must still open after the
    // defaults are raised, which means reading them from the blob rather than
    // assuming today's values.
    final phone = await makeDevice('u1');
    await KeyRecovery(backend: backend, storage: phone.storage).save('a passphrase for the test');
    final weakened = backend.keyBackup!;
    backend.keyBackup = KeyBackupPayload(
      salt: weakened.salt,
      nonce: weakened.nonce,
      blob: weakened.blob,
      kdf: weakened.kdf,
      memoryKiB: 8 * 1024, // not what this build uses
      iterations: 1,
      parallelism: 1,
      version: weakened.version,
    );
    // The blob was sealed with the real parameters, so this must now fail — which
    // is the proof that the parameters are read from the backup at all.
    final fresh = MemoryKeyStorage();
    await expectLater(
      KeyRecovery(backend: backend, storage: fresh).restore('a passphrase for the test'),
      throwsA(isA<WrongPassphrase>()),
    );
  });
}
