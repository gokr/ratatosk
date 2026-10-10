import 'package:connectrpc/connect.dart' show HttpClient;

/// Fallback used only if neither dart:io nor dart:js_interop is available,
/// which cannot happen on a platform Flutter supports.
HttpClient createConnectHttpClient() =>
    throw UnsupportedError('no HTTP client for this platform');
