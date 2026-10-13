import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../api/backend.dart';
import '../state/app_state.dart';
import 'url_opener_stub.dart';
import 'language.dart';

/// "Ways to sign in" — the list of methods an account has, and the two actions that
/// change it.
///
/// This is the answer to "how do I connect Google to my existing account": signing in
/// with Google cannot do it, because signing in with an identity nobody has linked
/// can only ever create a *new* account. Attaching an identity to an account you
/// already have is a different act, and it happens here.
///
/// It is also the screen that tells you when an account has only one way in, which is
/// the thing worth knowing *before* it matters.
class SignInMethodsTile extends StatelessWidget {
  const SignInMethodsTile({super.key, required this.methods});

  final SignInMethods methods;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Loads and shows the account's sign-in methods.
class SignInMethodsSection extends StatefulWidget {
  const SignInMethodsSection({super.key});

  @override
  State<SignInMethodsSection> createState() => _SignInMethodsSectionState();
}

class _SignInMethodsSectionState extends State<SignInMethodsSection> {
  SignInMethods? _methods;
  bool _busy = false;
  String? _problem;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final methods = await di<ChatBackend>().signInMethods();
      if (!mounted) return;
      setState(() => _methods = methods);
    } catch (_) {
      // A server too old for the RPC, or unreachable: show nothing rather than a
      // screen that claims the account has no methods.
    }
  }

  Future<void> _connect() async {
    setState(() {
      _busy = true;
      _problem = null;
    });
    try {
      final url = await di<AppState>().googleLinkUrl();
      if (url.isEmpty) {
        setState(() {
          _busy = false;
          _problem = tr(context, 'This server does not offer Google sign-in.');
        });
        return;
      }
      final opened = await openExternalUrl(url);
      if (!opened) {
        setState(() {
          _busy = false;
          _problem = tr(context, 'Could not open the sign-in page.');
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _problem = tr(context, 'Could not start connecting Google.');
      });
    }
  }

  Future<void> _disconnect() async {
    setState(() {
      _busy = true;
      _problem = null;
    });
    final ok = await di<AppState>().unlinkGoogle();
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      await _load();
      return;
    }
    // The server refuses when Google is the only way in, and its sentence says so.
    setState(() => _problem =
        di<AppState>().lastError ?? tr(context, 'Could not disconnect Google.'));
  }

  @override
  Widget build(BuildContext context) {
    final methods = _methods;
    if (methods == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          leading: const Icon(Icons.login_outlined),
          title: Text(tr(context, 'Ways to sign in')),
          subtitle: Text(
            [
              if (methods.hasPassword) tr(context, 'Password'),
              if (methods.hasGoogle)
                methods.googleEmail.isEmpty
                    ? tr(context, 'Google')
                    : '${tr(context, 'Google')} · ${methods.googleEmail}',
            ].join(' · '),
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        // A warning rather than a refusal: one way in is a legitimate choice, but a
        // person should know that losing it loses the account.
        if (methods.hasPassword && !methods.hasGoogle || !methods.hasPassword && methods.hasGoogle)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Text(
              methods.hasPassword
                  ? tr(context, 'Google is not connected. Connecting it gives you a second way in.')
                  : tr(context, 'Google is the only way into this account. Set a password to add another.'),
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(spacing: 8, children: [
            if (!methods.hasGoogle)
              FilledButton.tonal(
                onPressed: _busy ? null : _connect,
                child: Text(tr(context, 'Connect Google')),
              ),
            if (methods.hasGoogle)
              OutlinedButton(
                onPressed: _busy ? null : _disconnect,
                child: Text(tr(context, 'Disconnect Google')),
              ),
          ]),
        ),
        if (_problem != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(_problem!,
                style: TextStyle(color: theme.colorScheme.error, fontSize: 12)),
          ),
      ],
    );
  }
}
