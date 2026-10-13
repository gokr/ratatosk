
import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../api/backend.dart';
import 'language.dart';
import 'url_opener_stub.dart';

/// Signing in with Google, which on every platform this app ships to is a browser
/// redirect.
///
/// There is no native Google SDK here, and that is a choice rather than a gap: the
/// server already runs a complete authorization-code + PKCE flow, and OAuth is a
/// redirect protocol. So "Sign in with Google" means: send the browser to the
/// server's start endpoint, let the server and Google do their part, and read the
/// result out of the URL the server sends the browser back to. That is one code path
/// instead of three SDK integrations, and it is the same path in the browser, on
/// Android and on iOS.
///
/// The result is in the query string because the server redirects to this app's own
/// origin. Nothing here is trusted: a pending token is single-use and the server
/// checks the invitation itself. A value in a URL is a *request* to finish signing
/// up; the server decides whether it is allowed.

/// The query parameters the server's callback adds.
const googlePendingParam = 'google_pending';
const googleTokenParam = 'google_token';
const googleErrorParam = 'google_error';
const googleSuggestedParam = 'google_suggested_username';
const googleEmailParam = 'google_email';
const googleLinkedParam = 'google_linked';
const googleLinkErrorParam = 'google_link_error';

/// Whether this server offers Google sign-in. Fetched once and remembered, so the
/// sign-in screen does not ask on every rebuild.
class GoogleSignIn extends ChangeNotifier {
  GoogleSignIn({required this.backend});

  final ChatBackend backend;

  GoogleSignInConfig? _config;
  GoogleSignInConfig? get config => _config;
  bool _loading = false;

  /// True only once the server has confirmed it is configured. Until then the button
  /// is hidden rather than shown-and-broken.
  bool get available => _config?.enabled ?? false;

  Future<void> load() async {
    if (_config != null || _loading) return;
    _loading = true;
    try {
      _config = await backend.googleSignInConfig();
    } catch (_) {
      // A server too old to have the RPC, or unreachable. Either way: no button.
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Sends the browser to the server, which sends it on to Google.
  ///
  /// The invitation code is *not* carried across the redirect: it is asked for on
  /// the way back, where the person can see what they are being asked for and where
  /// a mistyped code can be corrected without another trip through Google.
  Future<void> beginSignIn() async {
    final config = _config;
    if (config == null || !config.enabled) return;
    // One behaviour for every platform: hand the URL to the browser. On the web
    // that is the current tab and the callback comes back to this page; elsewhere
    // the platform's launcher takes it and the app is resumed through the link
    // controller, which already handles a custom-scheme return.
    final opened = await openExternalUrl(config.authorizationEndpoint);
    if (!opened) {
      throw StateError('no browser available to complete sign-in');
    }
  }
}

/// The sign-in state a Google round-trip left in the URL.
class GoogleCallbackResult {
  const GoogleCallbackResult({
    this.pendingToken,
    this.token,
    this.error,
    this.suggestedUsername,
    this.email,
    this.linked = false,
    this.linkError,
  });

  /// Set when a *linking* attempt finished: "1" means the identity is connected.
  final bool linked;
  /// Why connecting Google was refused, in the server's own words.
  final String? linkError;

  final String? pendingToken;
  final String? token;
  final String? error;
  final String? suggestedUsername;
  final String? email;

  bool get hasPending => pendingToken != null && pendingToken!.isNotEmpty;
  bool get hasSession => token != null && token!.isNotEmpty;
  bool get hasError => error != null && error!.isNotEmpty;
  bool get hasLinkResult => linked || (linkError != null && linkError!.isNotEmpty);
  bool get isEmpty =>
      !hasPending && !hasSession && !hasError && !hasLinkResult;
}

/// Reads and consumes the callback parameters from a URI.
///
/// On the web the result arrives on the page URL, which must then be cleaned: the
/// pending token is single-use, so leaving it in the address bar invites a reload to
/// look like a failure, and it would sit in the browser history.
GoogleCallbackResult readGoogleCallback(Uri uri) {
  final q = uri.queryParameters;
  return GoogleCallbackResult(
    pendingToken: q[googlePendingParam],
    token: q[googleTokenParam],
    error: q[googleErrorParam],
    suggestedUsername: q[googleSuggestedParam],
    email: q[googleEmailParam],
    linked: q[googleLinkedParam] == '1',
    linkError: q[googleLinkErrorParam],
  );
}

/// The URL without the sign-in parameters, so the address bar stops carrying a
/// token.
String stripGoogleParams(Uri uri) {
  final q = Map<String, String>.from(uri.queryParameters)
    ..remove(googlePendingParam)
    ..remove(googleTokenParam)
    ..remove(googleErrorParam)
    ..remove(googleSuggestedParam)
    ..remove(googleEmailParam)
    ..remove(googleLinkedParam)
    ..remove(googleLinkErrorParam);
  return Uri(
    scheme: uri.scheme,
    userInfo: uri.userInfo.isEmpty ? null : uri.userInfo,
    host: uri.host,
    port: uri.hasPort ? uri.port : null,
    path: uri.path,
    queryParameters: q.isEmpty ? null : q,
  ).toString();
}

/// The "Sign in with Google" button.
///
/// Drawn as our own button rather than Google's script: the alternative is loading
/// a third-party script into the sign-in page, which is a real cost in a product
/// whose selling point is that it talks to nobody but your own server. The branding
/// guidance is respected in the sense that matters — the button says what it does and
/// is not styled to look like something else.
class GoogleSignInButton extends StatefulWidget {
  const GoogleSignInButton({super.key});

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  bool _busy = false;
  String? _problem;

  Future<void> _start() async {
    setState(() {
      _busy = true;
      _problem = null;
    });
    try {
      await di<GoogleSignIn>().beginSignIn();
      // A redirect follows; do not clear the busy state, or the button flickers back
      // to enabled as the page unloads.
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _problem = 'Could not open the sign-in page.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        OutlinedButton.icon(
          onPressed: _busy ? null : _start,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            minimumSize: const Size.fromHeight(48),
          ),
          icon: const _GoogleMark(),
          label: Text(_busy
              ? tr(context, 'Opening Google…')
              : tr(context, 'Sign in with Google')),
        ),
        if (_problem != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_problem!,
                style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
          ),
      ],
    );
  }
}

/// The Google "G", drawn rather than fetched.
///
/// An image would be a network request to Google on the sign-in screen — before
/// anybody has signed in — which is exactly the kind of contact this product avoids.
/// Four arcs in the brand colours, at the size of an icon.
class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) => const SizedBox(
        width: 18,
        height: 18,
        child: CustomPaint(painter: _GoogleMarkPainter()),
      );
}

class _GoogleMarkPainter extends CustomPainter {
  const _GoogleMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.26;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    // The four arcs of the mark, in the brand colours, with the gap on the right
    // where the crossbar leaves.
    const start = -0.62;
    void arc(double from, double to, Color color) {
      paint.color = color;
      canvas.drawArc(rect, from, to - from, false, paint);
    }

    arc(start, 1.2, const Color(0xFF4285F4)); // blue
    arc(1.2, 2.6, const Color(0xFF34A853)); // green
    arc(2.6, 4.0, const Color(0xFFFBBC05)); // yellow
    arc(4.0, start + 6.28318, const Color(0xFFEA4335)); // red
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
