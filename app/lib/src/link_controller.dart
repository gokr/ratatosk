import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

/// Watches for invitation links arriving from outside the app: the custom
/// scheme `ratatosk://join/<code>` on mobile and desktop, and on the web either
/// `?invite=<code>` or the invite landing page's redirect.
///
/// It only records the code; deciding what to do with it (show the join screen,
/// redeem it) belongs to the UI.
class LinkController extends ChangeNotifier {
  LinkController({AppLinks? appLinks}) : _appLinks = appLinks;

  final AppLinks? _appLinks;
  StreamSubscription<Uri>? _subscription;
  String? _pendingInviteCode;

  /// A code that arrived and has not been handled yet.
  String? get pendingInviteCode => _pendingInviteCode;

  /// Starts listening. Safe to call once.
  Future<void> start() async {
    // The web build has no custom-scheme handler; its invitation arrives as a
    // query parameter on the page URL.
    if (kIsWeb) {
      consumeUri(Uri.base);
      return;
    }
    final links = _appLinks ?? AppLinks();
    try {
      final initial = await links.getInitialLink();
      if (initial != null) consumeUri(initial);
    } catch (_) {
      // No platform support (a desktop run without a .desktop entry, say) is
      // not an error worth surfacing.
    }
    _subscription = links.uriLinkStream.listen(consumeUri, onError: (Object _) {});
  }

  /// Extracts an invite code from a URI, if it carries one.
  ///
  /// Understands `ratatosk://join/CODE`, `https://host/join/CODE`,
  /// `https://host/?invite=CODE` and a bare code.
  void consumeUri(Uri uri) {
    final code = inviteCodeFrom(uri);
    if (code == null || code.isEmpty) return;
    _pendingInviteCode = code;
    notifyListeners();
  }

  /// Records a code typed or pasted by the user.
  void submitCode(String code) {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return;
    _pendingInviteCode = inviteCodeFrom(Uri.tryParse(trimmed) ?? Uri()) ?? trimmed;
    notifyListeners();
  }

  void clear() {
    if (_pendingInviteCode == null) return;
    _pendingInviteCode = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  /// The invite code carried by a URI, or null when it carries none.
  static String? inviteCodeFrom(Uri uri) {
    if (!uri.hasScheme && !uri.hasAuthority) {
      // A bare code, e.g. from a text field.
      final text = uri.toString().trim();
      return text.isEmpty ? null : text;
    }
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    final joinIndex = segments.indexOf('join');
    if (joinIndex >= 0 && joinIndex + 1 < segments.length) {
      return segments[joinIndex + 1];
    }
    // The host is used by the ratatosk:// scheme, where the code can be in
    // either the host or the first path segment.
    if (uri.scheme == 'ratatosk') {
      if (segments.isNotEmpty) return segments.first;
      if (uri.host.isNotEmpty && uri.host != 'join') return uri.host;
    }
    final query = uri.queryParameters['invite'];
    if (query != null && query.isNotEmpty) return query;
    return null;
  }
}
