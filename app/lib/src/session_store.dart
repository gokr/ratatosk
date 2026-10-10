import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The bits of configuration that have to survive a restart: the session token
/// and the server origin.
///
/// Kept behind one small class so nothing else in the app touches the platform
/// preferences plugin, which is what makes the rest of the app testable.
class SessionStore {
  static const _tokenKey = 'ratatosk.token';
  static const _baseUrlKey = 'ratatosk.baseUrl';

  Future<String?> readToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    return (token == null || token.isEmpty) ? null : token;
  }

  Future<void> writeToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    if (token.isEmpty) {
      await prefs.remove(_tokenKey);
    } else {
      await prefs.setString(_tokenKey, token);
    }
  }

  Future<Uri?> readBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_baseUrlKey);
    if (raw == null || raw.isEmpty) return null;
    return Uri.tryParse(raw);
  }

  Future<void> writeBaseUrl(Uri url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, url.toString());
  }

  /// The server to talk to when nothing is stored.
  ///
  /// `--dart-define=RATATOSK_URL=https://chat.example` wins, because that is
  /// what a release build needs. On the web the page's own origin is the sanest
  /// default: the invite landing page and the API are served by one server.
  /// Everywhere else it is the local development server.
  static Uri defaultBaseUrl() {
    const fromDefine = String.fromEnvironment('RATATOSK_URL');
    if (fromDefine.isNotEmpty) {
      final parsed = Uri.tryParse(fromDefine);
      if (parsed != null) return parsed;
    }
    if (kIsWeb) {
      return Uri.base.replace(path: '', query: '', fragment: '');
    }
    return Uri.parse('http://localhost:8080');
  }
}
