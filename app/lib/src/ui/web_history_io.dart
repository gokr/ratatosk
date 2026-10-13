/// No browser here, so there is no history to rewrite. A no-op rather than an
/// unsupported error: main.dart calls this on every platform.
void webHistoryReplace(String url) {}
