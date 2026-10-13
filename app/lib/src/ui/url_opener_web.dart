import 'package:web/web.dart' as web;

/// Navigates the current tab.
///
/// A top-level navigation rather than a popup: a popup is blocked by most browsers
/// when it is not the direct result of a click, and a sign-in that silently does
/// nothing because a popup was blocked is the worst possible outcome. This one
/// leaves the page, which is the point — OAuth is a redirect protocol.
Future<bool> openExternalUrl(String url) async {
  web.window.location.href = url;
  return true;
}
