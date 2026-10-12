import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../api/backend.dart';
import '../link_controller.dart';
import '../session_store.dart';
import '../state/app_state.dart';
import 'widgets/brand_logo.dart';

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
    final inviteCode = links.pendingInviteCode;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _Brand(),
                const SizedBox(height: 32),
                if (inviteCode != null) ...[
                  InviteBanner(code: inviteCode, onDismiss: links.clear),
                  const SizedBox(height: 16),
                ],
                _AuthForm(
                  busy: state.bootstrapping,
                  error: state.lastError,
                  onSignIn: state.signIn,
                  onSignUp: state.signUp,
                  inviteCode: inviteCode,
                ),
                const SizedBox(height: 24),
                const _ServerHint(),
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
        const BrandLogo(size: 96),
        const SizedBox(height: 16),
        Text(
          'Ratatosk',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          'Messages, groups and invitations',
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.mail_outline, color: scheme.onPrimaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'You have an invitation. Sign in or create an account to accept it.',
              style: TextStyle(color: scheme.onPrimaryContainer),
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: const Icon(Icons.close),
            tooltip: 'Dismiss',
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
  final Future<void> Function(String username, String password, String displayName) onSignUp;

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
      setState(() => _localError = 'Enter a username and password.');
      return;
    }
    if (_registering && password.length < 8) {
      setState(() => _localError = 'Passwords need at least 8 characters.');
      return;
    }
    setState(() => _localError = null);
    if (_registering) {
      await widget.onSignUp(username, password, _displayName.text.trim());
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
            decoration: const InputDecoration(
              hintText: 'Your name (optional)',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: _username,
          autocorrect: false,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            hintText: 'Username',
            prefixIcon: Icon(Icons.alternate_email),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _password,
          obscureText: _obscure,
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            hintText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(
            error,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 20),
        FilledButton(
          onPressed: widget.busy ? null : _submit,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          child: Text(_registering ? 'Create account' : 'Sign in'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: widget.busy
              ? null
              : () => setState(() {
                    _registering = !_registering;
                    _localError = null;
                  }),
          child: Text(
            _registering ? 'I already have an account' : 'Create a new account',
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
        const SizedBox(width: 8),
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
          child: const Text('Change'),
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
      title: const Text('Server address'),
      content: TextField(
        controller: controller,
        autocorrect: false,
        decoration: const InputDecoration(hintText: 'https://chat.example'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: const Text('Save'),
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
      title: const Text('Restart to apply'),
      content: Text('Ratatosk will use $uri after a restart.'),
      actions: [
        FilledButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
      ],
    ),
  );
}
