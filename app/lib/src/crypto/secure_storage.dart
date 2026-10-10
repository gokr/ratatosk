// The platform keystore: Keychain on Apple platforms, Keystore on Android,
// libsecret on Linux, DPAPI on Windows, and the browser's own encrypted storage
// on the web.
//
// Scalars go in and out base64-encoded so the storage layer never has to deal
// with binary. A platform without a usable keystore falls back to
// [MemoryKeyStorage], which keeps the app working for one session and loses the
// keys at exit — loudly, through [available], rather than silently writing
// private keys to plain disk.
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'identity.dart';

/// The real key store.
class SecureKeyStorage implements PrivateKeyStorage {
  SecureKeyStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  /// Whether the platform keystore could be used at all.
  bool available = true;

  @override
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      // No keystore (a headless Linux box without libsecret, say). The app
      // still runs; the identity is simply not durable.
      available = false;
      return null;
    }
  }

  @override
  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {
      available = false;
    }
  }

  @override
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (_) {
      available = false;
    }
  }
}
