import 'package:flutter/material.dart';
import '../language.dart';

import '../../session_store.dart';
import '../../state/app_state.dart';
import '../settings_page.dart';

/// Offers key recovery once, on the first launch after signing in.
///
/// Skipping is allowed, because forcing it would mean a user who does not want a
/// passphrase cannot use the app at all. But skipping is *answered*, not silent: the
/// second step states plainly what it costs, which is history on a new device. A
/// warning nobody has to read is not a warning, and this is the one decision where
/// the consequence shows up months later.
///
/// Shown at most once. Anything more would train people to dismiss it.
Future<void> maybeOfferKeyRecovery(BuildContext context, AppState state, SessionStore session) async {
  if (state.me == null) return;
  if (await session.recoveryPromptShown()) return;
  if (!context.mounted) return;
  final messenger = ScaffoldMessenger.maybeOf(context);

  final wants = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(tr(context, 'Protect your messages across devices?')),
      content: SizedBox(
        width: 360,
        child: Text(
          tr(context, 'Your encryption keys live only on this device. With a recovery passphrase, a new phone or a reinstall can still read your history.\n\nThe passphrase is never sent to the server, and it cannot be reset.'),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(tr(context, 'Not now')),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(tr(context, 'Set up recovery')),
        ),
      ],
    ),
  );

  if (wants == true) {
    if (context.mounted) await showKeyRecoveryDialog(context);
    await session.markRecoveryPromptShown();
    return;
  }

  // The skip path: say what it costs, and let them change their mind right here.
  if (context.mounted) {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr(context, 'Continue without recovery?')),
        content: SizedBox(
          width: 360,
          child: Text(
            tr(context, 'If you reinstall the app or move to a new phone, messages you have already received will not be readable there. They are not lost from the server — but nothing can open them without the keys on this device.\n\nYou can set this up later in Settings.'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(tr(context, 'Set up recovery')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(tr(context, 'Continue without it')),
          ),
        ],
      ),
    );
    if (confirmed == false && context.mounted) {
      await showKeyRecoveryDialog(context);
    }
  }
  await session.markRecoveryPromptShown();
  if (context.mounted && wants == null) {
    messenger?.showSnackBar(SnackBar(
      content: Text(tr(context, 'You can set up key recovery any time in Settings.')),
    ));
  }
}
