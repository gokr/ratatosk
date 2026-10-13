// Key recovery: an encrypted backup of this install's encryption identity.
//
// Why it exists: a device's private keys live only in that device's keystore. Sign
// in on a new phone, or reinstall the app, and those keys are gone — so every
// message the user already received stays unreadable for good. Encryption cannot
// fix that after the fact, so the fix is to keep a copy the user controls.
//
// What the server holds is a blob it cannot open: the payload is sealed with a key
// derived from a passphrase the user chose, and the passphrase never leaves the
// device. That keeps the property the whole design rests on — a compromised server
// yields nothing — while making "I got a new phone" survivable.
//
// The honest limits, which the UI has to state rather than imply:
//
//   * Losing the passphrase means the backup is unopenable. There is no reset,
//     because a reset would be a way for someone else to open it too.
//   * A backup only ever opens messages received *after* it was made. Keys for
//     earlier epochs were never escrowed anywhere, so those stay sealed.
import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography_plus/cryptography_plus.dart' as c;

import '../api/backend.dart';
import 'crypto.dart';
import 'identity.dart';
import 'manager.dart';

/// A fetched backup plus the metadata needed to open it.
class RecoveryBackup {
  RecoveryBackup({
    required this.salt,
    required this.nonce,
    required this.blob,
    required this.memoryKiB,
    required this.iterations,
    required this.parallelism,
    required this.version,
  });

  final Uint8List salt;
  final Uint8List nonce;
  final Uint8List blob;
  final int memoryKiB;
  final int iterations;
  final int parallelism;
  final String version;
}

/// Marks a passphrase that does not open the backup.
///
/// Distinct from a transport failure so the UI can say "that passphrase is wrong"
/// rather than "something went wrong" — the difference matters when the user has
/// three passphrases in mind.
class WrongPassphrase implements Exception {
  const WrongPassphrase();
  @override
  String toString() => 'that recovery passphrase does not open this backup';
}

class KeyRecovery {
  KeyRecovery({
    required this.backend,
    required this.storage,
    RatatoskCrypto? crypto,
  }) : crypto = crypto ?? RatatoskCrypto();

  final ChatBackend backend;
  final PrivateKeyStorage storage;
  final RatatoskCrypto crypto;

  /// The payload format this build writes.
  static const version = 'ratatosk/keys/v1';

  /// Binds the ciphertext to its purpose, so a backup blob cannot be replayed as
  /// something else (and a message cannot be passed off as a backup).
  static const _aad = 'ratatosk/keys/v1/backup';

  /// Argon2id work factor. 64 MiB and 3 passes is the OWASP-recommended floor and
  /// takes well under a second on a phone, which is the balance that matters here:
  /// a user waits once, an attacker pays per guess.
  static const _memoryKiB = 64 * 1024;
  static const _iterations = 3;
  static const _parallelism = 2;
  static const _keyBytes = 32;

  /// The storage slots that make up the identity. A backup is exactly these, so
  /// restoring it restores the ability to open history and nothing else.
  static const slots = <String>[
    IdentityManager.identityKeySlot,
    IdentityManager.signingKeySlot,
    IdentityManager.deviceIdSlot,
    senderKeysSlot,
  ];

  /// Whether the account has a backup at all, without fetching its contents.
  Future<bool> hasBackup() async => (await fetch()) != null;

  Future<RecoveryBackup?> fetch() async {
    final stored = await backend.getKeyBackup();
    if (stored == null) return null;
    return RecoveryBackup(
      salt: Uint8List.fromList(stored.salt),
      nonce: Uint8List.fromList(stored.nonce),
      blob: Uint8List.fromList(stored.blob),
      memoryKiB: stored.memoryKiB,
      iterations: stored.iterations,
      parallelism: stored.parallelism,
      version: stored.version,
    );
  }

  /// Seals this device's keys under [passphrase] and uploads them.
  ///
  /// Called when the user turns recovery on, and again whenever the keys change
  /// (a new device's keys after a restore, or a passphrase change). Uploading
  /// replaces any previous backup: keeping the old blob would mean a passphrase the
  /// user just retired still opened their keys.
  Future<void> save(String passphrase) async {
    if (passphrase.trim().length < 8) {
      throw ArgumentError('a recovery passphrase should be at least 8 characters');
    }
    final payload = <String, String>{};
    for (final slot in slots) {
      final value = await storage.read(slot);
      if (value != null && value.isNotEmpty) payload[slot] = value;
    }
    if (payload.isEmpty) {
      throw StateError('there is nothing to back up on this device yet');
    }

    final salt = await crypto.randomBytes(16);
    final derived = await _deriveKey(
      passphrase,
      salt,
      memoryKiB: _memoryKiB,
      iterations: _iterations,
      parallelism: _parallelism,
    );
    final sealed = await crypto.seal(
      key: derived,
      plaintext: utf8.encode(jsonEncode({
        'version': version,
        'slots': payload,
      })),
      aad: _aad,
    );
    await backend.putKeyBackup(KeyBackupPayload(
      salt: salt,
      nonce: sealed.nonce,
      blob: sealed.combined,
      kdf: 'argon2id',
      memoryKiB: _memoryKiB,
      iterations: _iterations,
      parallelism: _parallelism,
      version: version,
    ));
  }

  /// Opens the account's backup and writes its keys into [storage].
  ///
  /// Returns the slots that were restored, so the caller can report what happened
  /// rather than assume. Throws [WrongPassphrase] when the passphrase does not
  /// open it, and [StateError] when the account has no backup.
  ///
  /// The KDF parameters come from the backup, not from this build's defaults: one
  /// written when the work factor was lower must still open.
  Future<List<String>> restore(String passphrase) async {
    final backup = await fetch();
    if (backup == null) {
      throw StateError('this account has no key backup');
    }
    final derived = await _deriveKey(
      passphrase,
      backup.salt,
      memoryKiB: backup.memoryKiB,
      iterations: backup.iterations,
      parallelism: backup.parallelism,
    );
    final Uint8List clear;
    try {
      clear = await crypto.unseal(
        key: derived,
        sealed: Sealed.fromCombined(backup.blob, backup.nonce),
        aad: _aad,
      );
    } on CryptoFailure {
      // Argon2id with the wrong passphrase yields the wrong key, and the AEAD
      // refuses it. This is the only place the app can tell a typo from a
      // corrupt backup, and it is a typo far more often.
      throw const WrongPassphrase();
    }
    final decoded = jsonDecode(utf8.decode(clear));
    if (decoded is! Map || decoded['slots'] is! Map) {
      throw StateError('the backup is not in a format this version understands');
    }
    final restored = <String>[];
    (decoded['slots'] as Map).forEach((key, value) {
      if (key is String && value is String && slots.contains(key)) {
        restored.add(key);
      }
    });
    if (restored.isEmpty) {
      throw StateError('the backup contains no key material');
    }
    for (final slot in restored) {
      await storage.write(slot, (decoded['slots'] as Map)[slot] as String);
    }
    return restored;
  }

  /// Removes the account's backup. The keys on this device are untouched.
  Future<void> remove() => backend.deleteKeyBackup();

  Future<Uint8List> _deriveKey(
    String passphrase,
    List<int> salt, {
    required int memoryKiB,
    required int iterations,
    required int parallelism,
  }) async {
    final kdf = c.Argon2id(
      parallelism: parallelism,
      memory: memoryKiB,
      iterations: iterations,
      hashLength: _keyBytes,
    );
    final key = await kdf.deriveKey(
      secretKey: c.SecretKey(utf8.encode(passphrase)),
      nonce: salt,
    );
    return Uint8List.fromList(await key.extractBytes());
  }
}
