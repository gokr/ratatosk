import 'bridge.dart';

PushBridge createPushBridge() => _NativePushBridge();

class _NativePushBridge implements PushBridge {
  @override
  Future<Map<String, dynamic>> status() async => {
    'supported': false,
    'reason': 'Web Push is available in the HTTPS web app. On iOS 16.4 or later, add it to your Home Screen first.',
    'subscribed': false,
  };
  @override
  Future<Map<String, dynamic>> enable(String publicKey) async => {};
  @override
  Future<Map<String, dynamic>?> subscription() async => null;
  @override
  Future<void> unsubscribe() async {}
}
