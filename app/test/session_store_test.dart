// The base URL the app derives from the page it is served on.
//
// This is small and easy to get wrong in a way that only shows up in a browser:
// the Connect transport appends a procedure to the base URL by string
// concatenation, so a stray "?" or "#" in it swallows every RPC.
import 'package:flutter_test/flutter_test.dart';
import 'package:ratatosk/src/session_store.dart';

/// The url an RPC would actually be sent to, computed the way the Connect
/// transport computes it: it strips trailing slashes off the base and the
/// procedure already starts with one.
String rpcUrl(Uri base, String procedure) =>
    '${base.toString().replaceAll(RegExp(r'/+$'), '')}$procedure';

void main() {
  group('baseUrlFrom', () {
    test('keeps the origin and drops the page path', () {
      expect(rpcUrl(SessionStore.baseUrlFrom(Uri.parse('http://localhost:8080/')),
              '/ratatosk.v1.AuthService/Register'),
          'http://localhost:8080/ratatosk.v1.AuthService/Register');
      expect(rpcUrl(SessionStore.baseUrlFrom(Uri.parse('http://127.0.0.1:8080/index.html')),
              '/ratatosk.v1.AuthService/Register'),
          'http://127.0.0.1:8080/ratatosk.v1.AuthService/Register');
      expect(SessionStore.baseUrlFrom(Uri.parse('http://127.0.0.1:8123')).hasPort, isTrue);
    });

    test('carries no query or fragment, which would otherwise swallow the procedure', () {
      final base = SessionStore.baseUrlFrom(
        Uri.parse('https://chat.example/?invite=abc123#/some/route'),
      );
      expect(base.hasQuery, isFalse);
      expect(base.hasFragment, isFalse);
      // The concatenation the transport actually performs.
      expect(rpcUrl(base, '/ratatosk.v1.AuthService/Register'),
          'https://chat.example/ratatosk.v1.AuthService/Register');
    });

    test('keeps a deployment sub-path', () {
      final base = SessionStore.baseUrlFrom(Uri.parse('https://host.example/ratatosk/?x=1'));
      expect(base.path, '/ratatosk/');
      expect(rpcUrl(base, '/ratatosk.v1.AuthService/Register'),
          'https://host.example/ratatosk/ratatosk.v1.AuthService/Register');
    });

    test('keeps a non-default port and https', () {
      expect(rpcUrl(SessionStore.baseUrlFrom(Uri.parse('https://host:8443/app')), '/pkg.S/M'),
          'https://host:8443/pkg.S/M');
      expect(rpcUrl(SessionStore.baseUrlFrom(Uri.parse('http://127.0.0.1:8123')), '/pkg.S/M'),
          'http://127.0.0.1:8123/pkg.S/M');
    });
  });
}
