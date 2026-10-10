// Picks the right HTTP client for the platform the app is running on.
//
// The Connect transport is the same everywhere, but the underlying HTTP client
// is not: native builds use dart:io (HTTP/1.1, which the Connect protocol is
// happy with), while web builds must use fetch. Dart cannot import both, so the
// choice is made at compile time through a conditional export.
export 'http_client_stub.dart'
    if (dart.library.io) 'http_client_io.dart'
    if (dart.library.js_interop) 'http_client_web.dart';
