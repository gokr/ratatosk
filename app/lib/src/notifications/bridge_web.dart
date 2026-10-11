import 'dart:convert';
import 'dart:js_interop';

import 'bridge.dart';

@JS('ratatoskPush.status')
external JSPromise<JSString> _status();
@JS('ratatoskPush.enable')
external JSPromise<JSString> _enable(JSString key);
@JS('ratatoskPush.subscription')
external JSPromise<JSString> _subscription();
@JS('ratatoskPush.unsubscribe')
external JSPromise<JSAny?> _unsubscribe();

PushBridge createPushBridge() => _WebPushBridge();

class _WebPushBridge implements PushBridge {
  @override
  Future<Map<String, dynamic>> status() async =>
      jsonDecode((await _status().toDart).toDart) as Map<String, dynamic>;
  @override
  Future<Map<String, dynamic>> enable(String publicKey) async =>
      jsonDecode((await _enable(publicKey.toJS).toDart).toDart) as Map<String, dynamic>;
  @override
  Future<Map<String, dynamic>?> subscription() async =>
      jsonDecode((await _subscription().toDart).toDart) as Map<String, dynamic>?;
  @override
  Future<void> unsubscribe() async { await _unsubscribe().toDart; }
}
