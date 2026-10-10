// The sealed store of this install's private keys, and the identity built on
// top of it.
//
// The private keys never leave the device and are never sent anywhere, so this
// store is the one place where losing data means losing history: a user who
// reinstalls cannot read what they could read before. That is the honest
// consequence of not backing keys up to the server (docs/E2EE.md §9).
import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography_plus/cryptography_plus.dart' as c;

import '../api/backend.dart';
import '../gen/ratatosk/v1/keys.pb.dart';
import 'crypto.dart';

/// Where private keys live. The app passes the platform's secure storage; tests
/// pass memory.
abstract interface class PrivateKeyStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// An in-memory store: tests, and any platform without a keystore.
class MemoryKeyStorage implements PrivateKeyStorage {
  final _values = <String, String>{};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;

  @override
  Future<void> delete(String key) async => _values.remove(key);
}

/// This install's identity: two key pairs, their public halves, and the device
/// key record the server knows them by.
class DeviceIdentity {
  DeviceIdentity({
    required this.crypto,
    required this.identityKeyPair,
    required this.signingKeyPair,
    required this.identityPublicKey,
    required this.signingPublicKey,
    required this.deviceKeyId,
    required this.fingerprint,
  });

  final RatatoskCrypto crypto;
  final c.SimpleKeyPair identityKeyPair;
  final c.SimpleKeyPair signingKeyPair;

  /// Raw X25519 public key (32 bytes).
  final Uint8List identityPublicKey;

  /// Raw Ed25519 public key (32 bytes).
  final Uint8List signingPublicKey;

  /// The server-assigned id of this device key; empty until registered.
  final String deviceKeyId;

  /// Hex SHA-256 of the id and both public keys. Every key derivation and every
  /// safety number is bound to it.
  final String fingerprint;

  c.SimplePublicKey get identityPublic => crypto.identityPublic(identityPublicKey);
  c.SimplePublicKey get signingPublic => crypto.signingPublic(signingPublicKey);

  DeviceIdentity copyWith({String? deviceKeyId, String? fingerprint}) => DeviceIdentity(
        crypto: crypto,
        identityKeyPair: identityKeyPair,
        signingKeyPair: signingKeyPair,
        identityPublicKey: identityPublicKey,
        signingPublicKey: signingPublicKey,
        deviceKeyId: deviceKeyId ?? this.deviceKeyId,
        fingerprint: fingerprint ?? this.fingerprint,
      );
}

/// Loads, creates and registers this install's identity.
class IdentityManager {
  IdentityManager({
    required this.backend,
    required this.storage,
    RatatoskCrypto? crypto,
  }) : crypto = crypto ?? RatatoskCrypto();

  final ChatBackend backend;
  final PrivateKeyStorage storage;
  final RatatoskCrypto crypto;

  static const _identityKeySlot = 'ratatosk.identity.private';
  static const _signingKeySlot = 'ratatosk.signing.private';
  static const _deviceIdSlot = 'ratatosk.device.id';

  DeviceIdentity? _current;
  DeviceIdentity? get current => _current;

  /// Loads the stored identity, creating and registering one on first run.
  ///
  /// Safe to call repeatedly; the work happens once per process.
  Future<DeviceIdentity> ensureIdentity({String label = '', String platform = ''}) async {
    final existing = _current;
    if (existing != null) return existing;

    final identityBytes = await storage.read(_identityKeySlot);
    final signingBytes = await storage.read(_signingKeySlot);

    if (identityBytes == null || signingBytes == null) {
      final created = await _generate();
      final registered = await _register(created, label: label, platform: platform);
      await _persist(registered);
      _current = registered;
      return registered;
    }

    final identityPair = await crypto.identityFromSeed(base64Decode(identityBytes));
    final signingPair = await crypto.signingFromSeed(base64Decode(signingBytes));
    final identityPublic = await crypto.publicKeyBytes(identityPair);
    final signingPublic = await crypto.publicKeyBytes(signingPair);
    final deviceKeyId = await storage.read(_deviceIdSlot) ?? '';

    final loaded = DeviceIdentity(
      crypto: crypto,
      identityKeyPair: identityPair,
      signingKeyPair: signingPair,
      identityPublicKey: identityPublic,
      signingPublicKey: signingPublic,
      deviceKeyId: deviceKeyId,
      fingerprint: await crypto.fingerprint(
        deviceKeyId: deviceKeyId,
        identityPublicKey: identityPublic,
        signingPublicKey: signingPublic,
      ),
    );

    // Re-register on every start: it is idempotent, it repairs a device key the
    // server no longer has, and it refreshes the label and last-seen time.
    final registered = await _register(loaded, label: label, platform: platform);
    await _persist(registered);
    _current = registered;
    return registered;
  }

  Future<DeviceIdentity> _generate() async {
    final identity = await crypto.newIdentityKeyPair();
    final signing = await crypto.newSigningKeyPair();
    final identityPublic = await crypto.publicKeyBytes(identity);
    final signingPublic = await crypto.publicKeyBytes(signing);
    return DeviceIdentity(
      crypto: crypto,
      identityKeyPair: identity,
      signingKeyPair: signing,
      identityPublicKey: identityPublic,
      signingPublicKey: signingPublic,
      deviceKeyId: '',
      // The fingerprint covers the device key id, which only exists once the
      // server has assigned one; this value is replaced by _register.
      fingerprint: await crypto.fingerprint(
        deviceKeyId: '',
        identityPublicKey: identityPublic,
        signingPublicKey: signingPublic,
      ),
    );
  }

  Future<DeviceIdentity> _register(DeviceIdentity identity, {String label = '', String platform = ''}) async {
    final key = await backend.publishDeviceKey(
      id: identity.deviceKeyId,
      identityPublicKey: identity.identityPublicKey,
      signingPublicKey: identity.signingPublicKey,
      label: label,
      platform: platform,
    );
    final fingerprint = await crypto.fingerprint(
      deviceKeyId: key.id,
      identityPublicKey: identity.identityPublicKey,
      signingPublicKey: identity.signingPublicKey,
    );
    // A server-reported fingerprint that disagrees with the locally computed
    // one means the key material was mangled or substituted in transit. The
    // client keeps its own value and refuses to continue quietly.
    if (key.fingerprint.isNotEmpty && key.fingerprint != fingerprint) {
      throw CryptoFailure(
        'the server reported a different fingerprint for this device key than the one computed locally',
      );
    }
    return identity.copyWith(deviceKeyId: key.id, fingerprint: fingerprint);
  }

  Future<void> _persist(DeviceIdentity identity) async {
    await storage.write(
      _identityKeySlot,
      base64Encode(await crypto.privateKeyBytes(identity.identityKeyPair)),
    );
    await storage.write(
      _signingKeySlot,
      base64Encode(await crypto.privateKeyBytes(identity.signingKeyPair)),
    );
    await storage.write(_deviceIdSlot, identity.deviceKeyId);
  }

  /// Forgets this install's keys.
  ///
  /// Past messages become unreadable, which is what "delete my keys" has to
  /// mean; the client also drops its cached plaintext when it does this.
  Future<void> forget() async {
    await storage.delete(_identityKeySlot);
    await storage.delete(_signingKeySlot);
    await storage.delete(_deviceIdSlot);
    _current = null;
  }

  /// The device keys of other users, fetched on demand and not cached here: the
  /// session layer knows when its cache is stale (a member joined, a key was
  /// revoked).
  Future<List<DeviceKey>> deviceKeysOf(List<String> userIds) => backend.listDeviceKeys(userIds);

  /// Publishes this device's own key so peers can encrypt to it.
  Future<DeviceKey> publish({String label = '', String platform = ''}) async {
    final identity = await ensureIdentity(label: label, platform: platform);
    return backend.publishDeviceKey(
      id: identity.deviceKeyId,
      identityPublicKey: identity.identityPublicKey,
      signingPublicKey: identity.signingPublicKey,
      label: label,
      platform: platform,
    );
  }
}
