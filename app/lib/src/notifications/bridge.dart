/// Platform boundary; only explicit enable calls may request permission.
abstract interface class PushBridge {
  Future<Map<String, dynamic>> status();
  Future<Map<String, dynamic>> enable(String publicKey);
  Future<Map<String, dynamic>?> subscription();
  Future<void> unsubscribe();
}
