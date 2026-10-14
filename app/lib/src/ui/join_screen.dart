import 'package:flutter/material.dart';
import 'language.dart';
import 'package:watch_it/watch_it.dart';

import '../api/backend.dart';
import '../state/app_state.dart';
import 'chat_page.dart';
import 'theme.dart';
import 'widgets/avatar.dart';

/// The screen an invitation opens: who invited you, whether the link still
/// works, and one button to accept.
///
/// Reached from a `ratatosk://join/<code>` deep link, from `?invite=<code>` on
/// the web, or by pasting a code. The preview is fetched without a token, so the
/// inviter is named even before signing in — but accepting requires a session,
/// which is why this screen only appears inside the signed-in shell.
class JoinScreen extends WatchingStatefulWidget {
  const JoinScreen({super.key, required this.code, required this.onDone});

  final String code;

  /// Called when the screen is left, so the pending invitation is forgotten.
  final VoidCallback onDone;

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  InvitePreview? _preview;
  bool _loading = true;
  bool _accepting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final preview = await di<AppState>().previewInvite(widget.code);
    if (!mounted) return;
    setState(() {
      _preview = preview;
      _loading = false;
    });
  }

  Future<void> _accept() async {
    setState(() {
      _accepting = true;
      _error = null;
    });
    final result = await di<AppState>().redeemInvite(widget.code);
    if (!mounted) return;
    setState(() => _accepting = false);
    if (result == null) {
      // The state layer already recorded the reason in `lastError`; keep the
      // screen usable so another attempt or a different link is possible.
      setState(() => _error = di<AppState>().lastError ?? 'That invitation could not be accepted.');
      di<AppState>().clearError();
      return;
    }
    widget.onDone();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => ChatPage(conversationId: result.conversation.id)),
    );
  }

  void _decline() {
    widget.onDone();
    final navigator = Navigator.of(context);
    if (navigator.canPop()) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: tr(context, 'Not now'),
          onPressed: _decline,
        ),
        title: Text(tr(context, 'Invitation')),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (preview?.inviter != null) ...[
                        Avatar.user(preview!.inviter!, size: 96, resolveUrl: di<AppState>().fileUrl),
                        const SizedBox(height: 16),
                        Text(
                          trp(context, '{0} invited you', [preview.inviter!.displayName]),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '@${preview.inviter!.username}',
                          style: TextStyle(color: RatatoskTheme.of(context).timestamp),
                        ),
                        const SizedBox(height: 24),
                      ] else
                        const SizedBox(height: 8),
                      if (preview == null || !preview.valid) ...[
                        Icon(Icons.link_off, size: 48, color: Theme.of(context).colorScheme.error),
                        const SizedBox(height: 12),
                        Text(
                          preview == null
                              ? 'That invitation could not be loaded.'
                              : _reasonText(preview),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 20),
                        FilledButton(onPressed: _decline, child: Text(tr(context, 'Close'))),
                      ] else ...[
                        Text(
                          tr(context, 'Accepting makes the two of you contacts and opens a private conversation.'),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: RatatoskTheme.of(context).timestamp),
                        ),
                        const SizedBox(height: 20),
                        if (_error != null) ...[
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Theme.of(context).colorScheme.error),
                          ),
                          const SizedBox(height: 12),
                        ],
                        FilledButton(
                          onPressed: _accepting ? null : _accept,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: _accepting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(tr(context, 'Accept invitation')),
                        ),
                        const SizedBox(height: 8),
                        TextButton(onPressed: _decline, child: Text(tr(context, 'Not now'))),
                      ],
                      const SizedBox(height: 24),
                      Text(
                        trp(context, 'Invite code {0}', [widget.code]),
                        style: TextStyle(fontSize: 12, color: RatatoskTheme.of(context).timestamp),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  static String _reasonText(InvitePreview preview) =>
      preview.detail.isNotEmpty ? preview.detail : 'This invitation is not available.';
}

/// A compact banner for the invite sheet's "somebody sent you this" path, used
/// when the user pastes a code rather than following a link.
class InviteErrorText extends StatelessWidget {
  const InviteErrorText({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) => Text(
        describeError(error),
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      );
}
