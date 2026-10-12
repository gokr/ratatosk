import 'dart:convert';
import 'package:connectrpc/connect.dart' as rpc;
import 'package:cryptography_plus/cryptography_plus.dart' as crypt;
import 'package:flutter/foundation.dart';
import '../api/http_client.dart';

/// Gravatar is explicit opt-in. Download locally and upload the chosen picture
/// so other users do not contact Gravatar or disclose their IPs/email hashes.
Future<Uint8List> fetchGravatar(String email) async {
  final normalized = email.trim().toLowerCase();
  if (!normalized.contains('@')) throw ArgumentError('Enter a valid email address');
  final hash = await crypt.Sha256().hash(utf8.encode(normalized));
  final digest = hash.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  final response = await createConnectHttpClient()(rpc.HttpRequest(
      'https://www.gravatar.com/avatar/$digest?s=256&d=404', 'GET', rpc.Headers(), null, null));
  if (response.status != 200) throw StateError('No Gravatar found (HTTP ${response.status})');
  final bytes = <int>[];
  await for (final chunk in response.body) {
    bytes.addAll(chunk);
    if (bytes.length > 2 * 1024 * 1024) throw StateError('Picture is too large');
  }
  return Uint8List.fromList(bytes);
}
