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
      return baseUrlFrom(Uri.base);
    }
    return Uri.parse('http://localhost:8080');
  }

  /// The API origin for a page served at [page].
  ///
  /// Built from parts rather than by `replace`ing the query and fragment away.
  /// `replace(query: '', fragment: '')` does not remove those parts, it sets
  /// them to *empty* — so the result renders as `http://host/?#`, and because
  /// the Connect transport appends a procedure by string concatenation, the
  /// request url becomes `http://host/?#/pkg.Service/Method`: the browser then
  /// sends `POST /?` and everything after the `#` never leaves the client. The
  /// server answers with the web app, and the client reports an unsupported
  /// content type.
  ///
  /// A sub-path is kept (a deployment under `https://host/app/` talks to
  /// `https://host/app`), so this is the directory of the page, not its origin.
  static Uri baseUrlFrom(Uri page) {
    final path = page.path;
    final directory = path.endsWith('/') ? path : path.substring(0, path.lastIndexOf('/') + 1);
    return Uri(
      scheme: page.scheme,
      userInfo: page.userInfo.isEmpty ? null : page.userInfo,
      host: page.host,
      port: page.hasPort ? page.port : null,
      path: directory,
    );
  }
}
