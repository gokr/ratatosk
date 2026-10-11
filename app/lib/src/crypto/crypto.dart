// End-to-end encryption, client side. See docs/E2EE.md for the protocol and its
// threat model; this file implements it.
//
// Layering:
//
//   RatatoskCrypto    primitives: keys, HKDF, AEAD, fingerprints, safety numbers
//   DeviceIdentity    this install's key pair plus its registration on the server
//   CryptoSession     conversation keys and group sender keys (the state above)
//   KeyStore          sealed-at-rest storage of the private keys
//
// Nothing in this file talks to the network; the session takes a `ChatBackend`
// and never hands it anything but ciphertext.
import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography_plus/cryptography_plus.dart' as c;

/// The protocol version. It is part of every HKDF salt and every AEAD's
/// associated data, so a future version can be added beside this one instead of
/// breaking it.
const cryptoVersion = 'ratatosk/v1';

/// Key and nonce sizes, fixed by the algorithms rather than by taste.
const identityKeyBytes = 32;
const signingKeyBytes = 32;
const symmetricKeyBytes = 32;
const nonceBytes = 24; // XChaCha20 uses a 192-bit nonce.

/// The cryptographic primitives, in one place.
///
/// A single instance is created at startup and shared: the algorithms are
/// stateless, and building them per call would only add allocation.
class RatatoskCrypto {
  RatatoskCrypto();

  final _x25519 = c.X25519();
  final _ed25519 = c.Ed25519();
  final _hkdf = c.Hkdf(hmac: c.Hmac.sha256(), outputLength: symmetricKeyBytes);
  final _aead = c.Xchacha20.poly1305Aead();
  final _sha256 = c.Sha256();

  /// Generates a fresh X25519 identity key pair.
  Future<c.SimpleKeyPair> newIdentityKeyPair() => _x25519.newKeyPair();

  /// Generates a fresh Ed25519 signing key pair.
  Future<c.SimpleKeyPair> newSigningKeyPair() => _ed25519.newKeyPair();

  Future<Uint8List> randomBytes(int length) async {
    final out = Uint8List(length);
    final random = c.SecureRandom.fast;
    for (var i = 0; i < length; i++) {
      out[i] = random.nextUint32() & 0xff;
    }
    return out;
  }

  /// The raw public key bytes of a key pair.
  Future<Uint8List> publicKeyBytes(c.SimpleKeyPair pair) async =>
      Uint8List.fromList((await pair.extractPublicKey()).bytes);

  /// The raw private key bytes of a key pair, for sealed storage.
  Future<Uint8List> privateKeyBytes(c.SimpleKeyPair pair) async =>
      Uint8List.fromList(await pair.extractPrivateKeyBytes());

  /// Rebuilds a key pair from its stored seed. X25519 and Ed25519 private keys
  /// are 32-byte seeds, which is exactly what `newKeyPairFromSeed` takes.
  Future<c.SimpleKeyPair> identityFromSeed(List<int> seed) =>
      _x25519.newKeyPairFromSeed(seed);

  Future<c.SimpleKeyPair> signingFromSeed(List<int> seed) =>
      _ed25519.newKeyPairFromSeed(seed);

  c.SimplePublicKey identityPublic(List<int> publicKey) =>
      c.SimplePublicKey(publicKey, type: c.KeyPairType.x25519);

  c.SimplePublicKey signingPublic(List<int> publicKey) =>
      c.SimplePublicKey(publicKey, type: c.KeyPairType.ed25519);

  /// X25519 agreement. Both sides compute the same secret from their own
  /// private key and the other's public key.
  Future<Uint8List> sharedSecret(c.SimpleKeyPair own, c.SimplePublicKey theirs) async {
    final secret = await _x25519.sharedSecretKey(keyPair: own, remotePublicKey: theirs);
    return Uint8List.fromList(await secret.extractBytes());
  }

  /// HKDF-SHA256 over [input], domain-separated by [salt] and [info].
  ///
  /// Every key in this protocol is derived through here, with the salt naming
  /// the purpose, so two keys can never collide even if their inputs do.
  Future<Uint8List> deriveKey({
    required List<int> input,
    required String salt,
    required String info,
  }) async {
    final key = await _hkdf.deriveKey(
      secretKey: c.SecretKey(input),
      nonce: utf8.encode(salt),
      info: utf8.encode(info),
    );
    return Uint8List.fromList(await key.extractBytes());
  }

  /// The conversation key of a direct chat: the same value on both sides, with
  /// no message exchanged.
  ///
  /// The fingerprints in `info` bind the key to the exact pair of identity keys
  /// it came from, and sorting them makes both sides agree without having to
  /// decide who is "first".
  Future<Uint8List> directConversationKey({
    required c.SimpleKeyPair own,
    required c.SimplePublicKey theirIdentity,
    required String ownFingerprint,
    required String theirFingerprint,
  }) async {
    final shared = await sharedSecret(own, theirIdentity);
    return deriveKey(
      input: shared,
      salt: '$cryptoVersion/direct',
      info: pairInfo(ownFingerprint, theirFingerprint),
    );
  }

  /// The key that seals one sender key for one recipient device.
  Future<Uint8List> envelopeKey({
    required c.SimpleKeyPair own,
    required c.SimplePublicKey theirIdentity,
    required String ownFingerprint,
    required String theirFingerprint,
  }) async {
    final shared = await sharedSecret(own, theirIdentity);
    return deriveKey(
      input: shared,
      salt: '$cryptoVersion/wrap',
      info: pairInfo(ownFingerprint, theirFingerprint),
    );
  }

  /// The order-independent identity of a key pair, used in every derivation.
  static String pairInfo(String a, String b) {
    final sorted = [a, b]..sort();
    return '$cryptoVersion/pair|${sorted[0]}|${sorted[1]}';
  }

  /// Seals [plaintext] under [key]. The associated data is authenticated but
  /// not encrypted, so the server cannot move a ciphertext to another
  /// conversation without it failing to open.
  Future<Sealed> seal({
    required List<int> key,
    required List<int> plaintext,
    required String aad,
    List<int>? nonce,
  }) async {
    final usedNonce = nonce ?? await randomBytes(nonceBytes);
    final box = await _aead.encrypt(
      plaintext,
      secretKey: c.SecretKey(key),
      nonce: usedNonce,
      aad: utf8.encode(aad),
    );
    return Sealed(
      ciphertext: Uint8List.fromList(box.cipherText),
      nonce: Uint8List.fromList(box.nonce),
      mac: Uint8List.fromList(box.mac.bytes),
    );
  }

  /// Opens a sealed value. Throws [CryptoFailure] when the key, the nonce or
  /// the associated data does not match — which is exactly how a tampered or
  /// replayed message is detected.
  Future<Uint8List> unseal({
    required List<int> key,
    required Sealed sealed,
    required String aad,
  }) async {
    try {
      final clear = await _aead.decrypt(
        c.SecretBox(sealed.ciphertext, nonce: sealed.nonce, mac: c.Mac(sealed.mac)),
        secretKey: c.SecretKey(key),
        aad: utf8.encode(aad),
      );
      return Uint8List.fromList(clear);
    } catch (error) {
      throw CryptoFailure('could not open this message with the key we have', cause: error);
    }
  }

  /// Ed25519 signature over [payload].
  ///
  /// The signing key is not needed to read messages; it exists so a device can
  /// authenticate its own key material, which is the basis for the key
  /// transparency work in docs/E2EE.md §9.
  Future<Uint8List> signWith(c.SimpleKeyPair signingKey, List<int> payload) async {
    final signature = await _ed25519.sign(payload, keyPair: signingKey);
    return Uint8List.fromList(signature.bytes);
  }

  /// Verifies a signature produced by [signWith].
  Future<bool> verifyWith(c.SimplePublicKey signingKey, List<int> payload, List<int> signature) =>
      _ed25519.verify(payload, signature: c.Signature(signature, publicKey: signingKey));

  /// SHA-256, hex encoded.
  Future<String> sha256Hex(List<int> input) async {
    final digest = await _sha256.hash(input);
    return _hex(Uint8List.fromList(digest.bytes));
  }

  /// The fingerprint of a device key, as shown to a human: it covers the
  /// server-assigned device id as well as the public keys, so two devices of one
  /// account are distinguishable. Defined identically on the server so both can
  /// display it; a client always recomputes it rather than trusting the copy it
  /// is sent.
  Future<String> fingerprint({
    required String deviceKeyId,
    required List<int> identityPublicKey,
    required List<int> signingPublicKey,
  }) =>
      sha256Hex([
        ...utf8.encode('$cryptoVersion/fingerprint|'),
        ...utf8.encode(deviceKeyId),
        ...utf8.encode('|'),
        ...identityPublicKey,
        ...utf8.encode('|'),
        ...signingPublicKey,
      ]);

  /// The fingerprint used for *key derivation* and safety numbers: it covers the
  /// public keys only.
  ///
  /// Deliberately not the display fingerprint. That one includes the device id,
  /// and the device id is assigned by the server: deriving a conversation key
  /// from it would give the server a lever over the cryptography — re-register a
  /// device under a new id and two peers stop agreeing on a key. Keys must depend
  /// on key material and nothing else.
  Future<String> keyFingerprint({
    required List<int> identityPublicKey,
    required List<int> signingPublicKey,
  }) =>
      sha256Hex([
        ...utf8.encode('$cryptoVersion/keyfp|'),
        ...identityPublicKey,
        ...utf8.encode('|'),
        ...signingPublicKey,
      ]);

  /// The safety number two users compare out of band.
  ///
  /// Twelve groups of five digits, so it can be read aloud without ambiguity.
  /// Both sides compute the same value; a malicious server that swapped a public
  /// key produces a different one. It digests the *key* fingerprints, so it
  /// changes only when key material does — not when the server re-registers a
  /// device under a new id.
  Future<String> safetyNumber(String fingerprintA, String fingerprintB) async {
    final sorted = [fingerprintA, fingerprintB]..sort();
    final digest = await sha256Hex([
      ...utf8.encode('$cryptoVersion/safety|'),
      ...utf8.encode(sorted[0]),
      ...utf8.encode('|'),
      ...utf8.encode(sorted[1]),
    ]);
    // Take 60 digits from the hex digest (it has 64) and lay them out in
    // groups, the way Signal's safety numbers do.
    final digits = <String>[];
    for (var i = 0; i < 12; i++) {
      final chunk = digest.substring(i * 5, i * 5 + 5);
      final value = int.parse(chunk, radix: 16) % 100000;
      digits.add(value.toString().padLeft(5, '0'));
    }
    return digits.join(' ');
  }

  static String _hex(Uint8List bytes) {
    final out = StringBuffer();
    for (final byte in bytes) {
      out.write(byte.toRadixString(16).padLeft(2, '0'));
    }
    return out.toString();
  }
}

/// A sealed value: ciphertext plus the nonce and tag needed to open it.
class Sealed {
  const Sealed({required this.ciphertext, required this.nonce, required this.mac});

  /// Reassembles a seal that was split into the ciphertext and tag carried by
  /// different protocol fields.
  factory Sealed.fromParts({
    required List<int> ciphertext,
    required List<int> nonce,
    required String mac,
  }) =>
      Sealed(
        ciphertext: Uint8List.fromList(ciphertext),
        nonce: Uint8List.fromList(nonce),
        mac: Uint8List.fromList(_fromHex(mac)),
      );

  final Uint8List ciphertext;
  final Uint8List nonce;
  final Uint8List mac;

  /// The tag as hex, for protocol fields that carry a string.
  String get macHex {
    final out = StringBuffer();
    for (final byte in mac) {
      out.write(byte.toRadixString(16).padLeft(2, '0'));
    }
    return out.toString();
  }

  /// The bytes to store: the tag is appended, which is what a single opaque
  /// blob in the wire protocol needs.
  Uint8List get combined => Uint8List.fromList([...ciphertext, ...mac]);

  /// Rebuilds a seal from `combined`, given the nonce.
  factory Sealed.fromCombined(List<int> combined, List<int> nonce, {int macBytes = 16}) {
    if (combined.length < macBytes) {
      throw CryptoFailure('sealed value is too short to contain a tag');
    }
    return Sealed(
      ciphertext: Uint8List.fromList(combined.sublist(0, combined.length - macBytes)),
      nonce: Uint8List.fromList(nonce),
      mac: Uint8List.fromList(combined.sublist(combined.length - macBytes)),
    );
  }

  static List<int> _fromHex(String hex) {
    if (hex.length.isOdd) throw CryptoFailure('odd-length hex tag');
    final out = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < out.length; i++) {
      out[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return out;
  }
}

/// Raised when a message cannot be opened: a wrong key, a tampered ciphertext,
/// or a message from an epoch whose key was never received.
class CryptoFailure implements Exception {
  CryptoFailure(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}
