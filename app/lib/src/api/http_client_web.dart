import 'package:connectrpc/connect.dart' show HttpClient;
import 'package:connectrpc/web.dart' as connect_web;

/// The browser HTTP client. Credentials stay same-origin: this app authenticates
/// with a bearer token, not with cookies, so it never needs the server to echo
/// permissive CORS credentials.
HttpClient createHttpClient() => connect_web.createHttpClient();
