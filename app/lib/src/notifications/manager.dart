import 'dart:convert';

import 'package:connectrpc/connect.dart' as rpc;
import 'package:flutter/foundation.dart';

import '../api/http_client.dart';
import 'bridge.dart';
import 'platform.dart';

typedef PushRequest = Future<Map<String, dynamic>> Function(
    String method, Uri url, String token, Map<String, dynamic>? body);

/// Opt-in browser notifications. Configuration is loaded ahead of the button
/// press so permission can be requested synchronously within user activation.
class PushManager extends ChangeNotifier {
  PushManager({required this.baseUrl, required this.token, PushBridge? bridge,
    PushRequest? request}) : bridge = bridge ?? createPushBridge(),
      request = request ?? _http;

  final Uri baseUrl;
  final String? Function() token;
  final PushBridge bridge;
  final PushRequest request;
  bool busy = false;
  bool supported = false;
  bool subscribed = false;
  bool serverEnabled = false;
  String publicKey = '';
  String message = 'Checking notification support…';
  bool _disposed = false;

  bool get canEnable => !busy && supported && serverEnabled && publicKey.isNotEmpty;

  Future<void> init() => _run(() async {
    final status = await bridge.status();
    supported = status['supported'] == true;
    subscribed = status['subscribed'] == true;
    if (!supported) {
      message = status['reason'] as String? ?? 'Notifications are not supported.';
      return;
    }
    final config = await _call('GET', '/api/push/config');
    serverEnabled = config['enabled'] == true;
    publicKey = config['publicKey'] as String? ?? '';
    message = !serverEnabled ? 'Notifications are not enabled on this server.'
        : subscribed ? 'This browser is subscribed. Enable again to sync with your account.'
        : status['permission'] == 'denied' ? 'Permission is blocked. Change browser/system notification settings to enable.'
        : 'Receive private “New message” alerts, even when the app is closed.';
  });

  /// No awaits before the browser bridge's permission call.
  Future<void> enable() {
    if (!canEnable) return Future.value();
    return _run(() async {
      final subscription = await bridge.enable(publicKey);
      // Whitelist the contract; expirationTime and browser extras stay local.
      await _call('POST', '/api/push/subscriptions', {
        'endpoint': subscription['endpoint'], 'keys': subscription['keys'],
      });
      subscribed = true;
      message = 'Notifications enabled. Alerts never include message contents.';
    });
  }

  Future<void> disable() => _run(() async {
    final subscription = await bridge.subscription();
    if (subscription != null) {
      // Delete first: a failed request must remain retryable with its endpoint.
      await _call('DELETE', '/api/push/subscriptions', {'endpoint': subscription['endpoint']});
    }
    await bridge.unsubscribe();
    subscribed = false;
    message = 'Notifications disabled for this browser.';
  });

  Future<Map<String, dynamic>> _call(String method, String path,
      [Map<String, dynamic>? body]) {
    final bearer = token();
    if (bearer == null || bearer.isEmpty) throw StateError('Sign in to manage notifications.');
    return request(method, baseUrl.resolve(path), bearer, body);
  }

  Future<void> _run(Future<void> Function() action) async {
    if (busy) return;
    busy = true;
    _notify();
    try { await action(); } catch (_) {
      message = 'Could not update notifications. Check permission, your connection and server configuration, then try again.';
    } finally { busy = false; _notify(); }
  }

  void _notify() { if (!_disposed) notifyListeners(); }
  @override
  void dispose() { _disposed = true; super.dispose(); }

  static Future<Map<String, dynamic>> _http(String method, Uri url,
      String token, Map<String, dynamic>? body) async {
    final headers = rpc.Headers();
    headers.set('authorization', ['Bearer $token']);
    headers.set('content-type', ['application/json']);
    final response = await createConnectHttpClient()(rpc.HttpRequest(
      url.toString(), method, headers,
      body == null ? null : Stream.value(Uint8List.fromList(utf8.encode(jsonEncode(body)))), null,
    ));
    final bytes = <int>[];
    await for (final chunk in response.body) { bytes.addAll(chunk); }
    if (response.status < 200 || response.status >= 300) {
      throw StateError('Push API failed (HTTP ${response.status}).');
    }
    return bytes.isEmpty ? {} : jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
  }
}
