import 'package:web/web.dart' as web;

/// Rewrites the current address without reloading or adding a history entry.
///
/// Used to take sign-in tokens out of the URL once they have been read: they are
/// single-use, so a reload should not look like a failure, and they should not sit
/// in the browser's history or in anything that copies the address bar.
void webHistoryReplace(String url) {
  web.window.history.replaceState(null, '', url);
}
