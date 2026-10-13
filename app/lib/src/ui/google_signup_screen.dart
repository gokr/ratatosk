import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../link_controller.dart';
import '../state/app_state.dart';
import 'google_signin.dart';
import 'language.dart';

/// Finishing a Google sign-up: a username and an invitation.
///
/// Shown after Google has confirmed *who* somebody is and the server has confirmed
/// they have no account here. Both fields are required, and the screen says so before
/// anything is submitted — this server is invite-only, and a person who has no code
/// should learn that here rather than after filling in a form.
///
/// The invitation is asked for now rather than carried through the redirect on
/// purpose: a mistyped code can be corrected here, without another trip through
/// Google, and the person can see what is being asked of them before they commit.
class GoogleSignUpScreen extends StatefulWidget {
  const GoogleSignUpScreen({
    super.key,
    required this.result,
    this.onDone,
  });

  final GoogleCallbackResult result;

  /// Called once the account exists. The manager has already signed in.
  final VoidCallback? onDone;

  @override
  State<GoogleSignUpScreen> createState() => _GoogleSignUpScreenState();
}

class _GoogleSignUpScreenState extends State<GoogleSignUpScreen> {
  final _username = TextEditingController();
  final _invite = TextEditingController();
  final _displayName = TextEditingController();
  bool _busy = false;
  String? _problem;

  @override
  void initState() {
    super.initState();
    // Pre-filled from the provider, editable: a suggestion is a convenience, not a
    // decision made on somebody's behalf.
    _username.text = widget.result.suggestedUsername ?? '';
    if (widget.result.email != null && widget.result.email!.isNotEmpty) {
      final at = widget.result.email!.indexOf('@');
      _displayName.text = at > 0 ? widget.result.email!.substring(0, at) : '';
    }
    // An invitation that arrived as a link is already known; use it without asking.
    final pending = di<LinkController>().pendingInviteCode;
    if (pending != null && pending.isNotEmpty) _invite.text = pending;
  }

  @override
  void dispose() {
    _username.dispose();
    _invite.dispose();
    _displayName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final username = _username.text.trim();
    final code = _invite.text.trim();
    if (username.isEmpty) {
      setState(() => _problem = tr(context, 'Choose a username.'));
      return;
    }
    if (code.isEmpty) {
      setState(() => _problem = tr(context, 'An invitation is required.'));
      return;
    }
    setState(() {
      _busy = true;
      _problem = null;
    });
    final ok = await di<AppState>().completeGoogleSignUp(
      pendingToken: widget.result.pendingToken!,
      username: username,
      inviteCode: code,
      displayName: _displayName.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      di<LinkController>().clear();
      widget.onDone?.call();
      return;
    }
    setState(() {
      _busy = false;
      // The manager recorded the server's own words: "that invitation is expired",
      // "that username is taken". Repeating them beats a generic failure, and the
      // server is the only party that knows which it is.
      _problem = di<AppState>().lastError ?? tr(context, 'Could not create the account.');
    });
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.result.email;
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, 'Finish signing up'))),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  tr(context, 'Google confirmed your identity.'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (email != null && email.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(email,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ),
                const SizedBox(height: 20),
                TextField(
                  controller: _username,
                  autocorrect: false,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: tr(context, 'Username'),
                    helperText: tr(context, 'Letters, digits, dot, dash or underscore'),
                    prefixIcon: const Icon(Icons.alternate_email),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _displayName,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: tr(context, 'Name'),
                    prefixIcon: const Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _invite,
                  autocorrect: false,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: tr(context, 'Invitation code'),
                    helperText: tr(context, 'This server is invite-only'),
                    prefixIcon: const Icon(Icons.mail_outline),
                  ),
                ),
                if (_problem != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(_problem!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  child: Text(_busy
                      ? tr(context, 'Creating…')
                      : tr(context, 'Create account')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The message shown when the server refused a sign-in, or Google did.
class GoogleErrorScreen extends StatelessWidget {
  const GoogleErrorScreen({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline,
                    size: 40, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 16),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: onRetry ?? () => di<AppState>().leaveGoogleFlow(),
                  child: Text(tr(context, 'Back')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
