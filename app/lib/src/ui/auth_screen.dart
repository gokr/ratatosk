import 'package:flutter/material.dart';
import 'language.dart';
import 'package:watch_it/watch_it.dart';

import '../api/backend.dart';
import '../link_controller.dart';
import '../session_store.dart';
import '../state/app_state.dart';
import 'google_signin.dart';
import 'widgets/brand_logo.dart';
import 'widgets/privacy_policy_link.dart';

/// Sign in, create an account, or accept an invitation.
///
/// One screen for all three: an invitation link usually arrives before an
/// account exists, so "join" has to offer registration without leaving the
/// page.
class AuthScreen extends WatchingWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = watchIt<AppState>();
    final links = watchIt<LinkController>();
    watchIt<GoogleSignIn>();
    final inviteCode = links.pendingInviteCode;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _Brand(),
                SizedBox(height: 32),
                if (inviteCode != null) ...[
                  InviteBanner(code: inviteCode, onDismiss: links.clear),
                  SizedBox(height: 16),
                ],
                // The button appears only when the server says it is configured:
                // showing it on a server without a client id would be a dead end.
                if (di<GoogleSignIn>().available) ...[
                  const GoogleSignInButton(),
                  const SizedBox(height: 16),
                  Row(children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(tr(context, 'or'),
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ),
                    const Expanded(child: Divider()),
                  ]),
                  const SizedBox(height: 16),
                ],
                _AuthForm(
                  busy: state.bootstrapping,
                  error: state.lastError,
                  onSignIn: state.signIn,
                  onSignUp: state.signUp,
                  inviteCode: inviteCode,
                ),
                SizedBox(height: 24),
                const _ServerHint(),
                // Above the server hint: a policy link is about the service, and
                // Google's OAuth review looks for it on the page users land on.
                Center(child: PrivacyPolicyLink()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BrandLogo(size: 96),
        SizedBox(height: 16),
        Text(
          tr(context, 'Ratatosk'),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 4),
        Text(
          tr(context, 'Messages, groups and invitations'),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

/// A banner shown while an invitation is waiting: the code survives a sign-up,
/// which is the whole point of remembering it in the link controller.
class InviteBanner extends StatelessWidget {
  const InviteBanner({super.key, required this.code, required this.onDismiss});

  final String code;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.mail_outline, color: scheme.onPrimaryContainer),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              tr(context, 'You have an invitation. Sign in or create an account to accept it.'),
              style: TextStyle(color: scheme.onPrimaryContainer),
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: Icon(Icons.close),
            tooltip: tr(context, 'Dismiss'),
          ),
        ],
      ),
    );
  }
}

class _AuthForm extends StatefulWidget {
  const _AuthForm({
    required this.busy,
    required this.onSignIn,
    required this.onSignUp,
    this.error,
    this.inviteCode,
  });

  final bool busy;
  final String? error;
  final String? inviteCode;
  final Future<void> Function(String username, String password) onSignIn;
  final Future<void> Function(String username, String password, String displayName,
      {String inviteCode}) onSignUp;

  @override
  State<_AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<_AuthForm> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _displayName = TextEditingController();
  bool _registering = false;
  bool _obscure = true;
  String? _localError;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _displayName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final username = _username.text.trim();
    final password = _password.text;
    if (username.isEmpty || password.isEmpty) {
      setState(() => _localError = tr(context, 'Enter a username and password.'));
      return;
    }
    if (_registering && password.length < 8) {
      setState(() => _localError = tr(context, 'Passwords need at least 8 characters.'));
      return;
    }
    setState(() => _localError = null);
    if (_registering) {
      // The code the screen was handed, finally used: signing up with an invitation
      // *is* how it is redeemed.
      await widget.onSignUp(username, password, _displayName.text.trim(),
          inviteCode: widget.inviteCode ?? '');
    } else {
      await widget.onSignIn(username, password);
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = _localError ?? widget.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_registering) ...[
          TextField(
            controller: _displayName,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              hintText: tr(context, 'Your name (optional)'),
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),
          SizedBox(height: 12),
        ],
        TextField(
          controller: _username,
          autocorrect: false,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            hintText: tr(context, 'Username'),
            prefixIcon: Icon(Icons.alternate_email),
          ),
        ),
        SizedBox(height: 12),
        TextField(
          controller: _password,
          obscureText: _obscure,
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            hintText: tr(context, 'Password'),
            prefixIcon: Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
        if (error != null) ...[
          SizedBox(height: 12),
          Text(
            error,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        SizedBox(height: 20),
        FilledButton(
          onPressed: widget.busy ? null : _submit,
          style: FilledButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 16),
            textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          child: Text(tr(context, _registering ? 'Create account' : 'Sign in')),
        ),
        SizedBox(height: 8),
        TextButton(
          onPressed: widget.busy
              ? null
              : () => setState(() {
                    _registering = !_registering;
                    _localError = null;
                  }),
          child: Text(
            tr(context, _registering ? 'I already have an account' : 'Create a new account'),
          ),
        ),
      ],
    );
  }
}

/// Where the app is pointed, with a way to change it. A self-hosted chat server
/// is the normal case, so the server address is a first-class setting rather
/// than something buried in a build flag.
class _ServerHint extends WatchingWidget {
  const _ServerHint();

  @override
  Widget build(BuildContext context) {
    final backend = di<ChatBackend>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.dns_outlined, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
        SizedBox(width: 8),
        Flexible(
          child: Text(
            backend.baseUrl.toString(),
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        TextButton(
          onPressed: () => showServerDialog(context),
          child: Text(tr(context, 'Change')),
        ),
      ],
    );
  }
}

/// Changes the server the app talks to. Restarting is the honest way to apply
/// it: every client holds a transport bound to the old origin.
Future<void> showServerDialog(BuildContext context) async {
  final session = di<SessionStore>();
  final current = di<ChatBackend>().baseUrl;
  final controller = TextEditingController(text: current.toString());
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(tr(context, 'Server address')),
      content: TextField(
        controller: controller,
        autocorrect: false,
        decoration: InputDecoration(hintText: 'https://chat.example'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(tr(context, 'Cancel'))),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: Text(tr(context, 'Save')),
        ),
      ],
    ),
  );
  controller.dispose();
  if (result == null || result.isEmpty) return;
  final uri = Uri.tryParse(result);
  if (uri == null || !uri.hasScheme) return;
  await session.writeBaseUrl(uri);
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(tr(context, 'Restart to apply')),
      content: Text(trp(context, 'Ratatosk will use {0} after a restart.', [uri])),
      actions: [
        FilledButton(onPressed: () => Navigator.pop(context), child: Text('OK')),
      ],
    ),
  );
}
