import 'package:flutter_test/flutter_test.dart';
import 'package:ratatosk/src/notifications/bridge.dart';
import 'package:ratatosk/src/notifications/bridge_stub.dart';
import 'package:ratatosk/src/notifications/manager.dart';

class FakeBridge implements PushBridge {
  int permissionRequests = 0;
  bool subscribed = false;
  final record = <String, dynamic>{
    'endpoint': 'https://push.example/sub',
    'keys': {'p256dh': 'key', 'auth': 'secret'},
    'expirationTime': null,
  };
  @override
  Future<Map<String, dynamic>> status() async => {
    'supported': true, 'subscribed': subscribed, 'permission': 'default',
  };
  @override
  Future<Map<String, dynamic>> enable(String publicKey) async {
    permissionRequests++;
    subscribed = true;
    return record;
  }
  @override
  Future<Map<String, dynamic>?> subscription() async => subscribed ? record : null;
  @override
  Future<void> unsubscribe() async { subscribed = false; }
}

void main() {
  test('native boundary is a no-op with no permission prompt', () async {
    final bridge = createPushBridge();
    expect((await bridge.status())['supported'], false);
    expect(await bridge.subscription(), null);
    await bridge.unsubscribe();
  });

  test('explicit enable posts only contract fields with current bearer', () async {
    final bridge = FakeBridge();
    final calls = <(String, Uri, String, Map<String, dynamic>?)>[];
    var bearer = 'first';
    final manager = PushManager(
      baseUrl: Uri.parse('https://chat.example'), token: () => bearer, bridge: bridge,
      request: (method, url, token, body) async {
        calls.add((method, url, token, body));
        return method == 'GET' ? {'enabled': true, 'publicKey': 'public'} : {};
      },
    );
    await manager.init();
    expect(bridge.permissionRequests, 0);
    expect(manager.canEnable, true);
    bearer = 'current';
    final enabling = manager.enable();
    expect(bridge.permissionRequests, 1, reason: 'bridge runs in the user activation, before await');
    await enabling;
    expect(calls.last.$1, 'POST');
    expect(calls.last.$2.path, '/api/push/subscriptions');
    expect(calls.last.$3, 'current');
    expect(calls.last.$4, {'endpoint': bridge.record['endpoint'], 'keys': bridge.record['keys']});
    expect(manager.subscribed, true);
    await manager.disable();
    expect(calls.last.$1, 'DELETE');
    expect(calls.last.$4, {'endpoint': bridge.record['endpoint']});
    expect(bridge.subscribed, false);
    expect(manager.subscribed, false);
    manager.dispose();
  });

  test('failed delete retains endpoint and allows retry', () async {
    final bridge = FakeBridge()..subscribed = true;
    var fail = true;
    final manager = PushManager(
      baseUrl: Uri.parse('https://chat.example'), token: () => 'token', bridge: bridge,
      request: (method, url, token, body) async {
        if (method == 'DELETE' && fail) throw StateError('offline');
        return {'enabled': true, 'publicKey': 'public'};
      },
    );
    await manager.init();
    await manager.disable();
    expect(manager.busy, false);
    expect(manager.subscribed, true);
    expect(bridge.subscribed, true);
    fail = false;
    await manager.disable();
    expect(bridge.subscribed, false);
    manager.dispose();
  });

  test('disabled server cannot request browser permission', () async {
    final bridge = FakeBridge();
    final manager = PushManager(
      baseUrl: Uri.parse('https://chat.example'), token: () => 'token', bridge: bridge,
      request: (method, url, token, body) async => {'enabled': false},
    );
    await manager.init();
    await manager.enable();
    expect(bridge.permissionRequests, 0);
    manager.dispose();
  });
}
