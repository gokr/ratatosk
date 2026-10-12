import 'package:file_selector/file_selector.dart';
import 'profile_photo.dart';
import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../api/backend.dart';
import '../gen/ratatosk/v1/social.pb.dart';
import '../state/app_state.dart';
import '../notifications/manager.dart';
import 'auth_screen.dart';
import 'theme.dart';
import 'widgets/avatar.dart';
import 'widgets/privacy_policy_link.dart';

/// Profile, contacts and the way out.
class SettingsPage extends WatchingWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // One watch per build, in a fixed order (watch_it's ordering rule). Every
    // value this screen shows lives on the same manager, so one watch covers
    // all of it.
    final state = watchIt<AppState>();
    final push = createOnce(() => PushManager(
      baseUrl: di<ChatBackend>().baseUrl, token: () => state.token,
    ));
    watch(push);
    callOnce((_) => push.init());
    final me = state.me;
    final contacts = state.contacts;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          if (me != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Avatar.user(me, size: 64, resolveUrl: state.fileUrl),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          me.displayName,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          '@${me.username}',
                          style: TextStyle(color: RatatoskTheme.of(context).timestamp),
                        ),
                        if (me.bio.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(me.bio),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Edit profile',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _showProfileDialog(context),
                  ),
                ],
              ),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.dns_outlined),
            title: const Text('Server'),
            subtitle: Text(di<ChatBackend>().baseUrl.toString()),
            onTap: () => showServerDialog(context),
          ),
          ListTile(
            leading: Icon(state.realtimeConnected ? Icons.cloud_done : Icons.cloud_off),
            title: const Text('Realtime connection'),
            subtitle: Text(state.realtimeConnected ? 'Connected' : 'Reconnecting…'),
            trailing: IconButton(
              tooltip: 'Reconnect now',
              icon: const Icon(Icons.refresh),
              onPressed: state.refresh,
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Message notifications'),
            subtitle: Text('${push.message}\nRequires HTTPS. On iOS/iPadOS 16.4+, use Share → Add to Home Screen, then open the installed app.'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(spacing: 12, children: [
              FilledButton(
                onPressed: push.canEnable ? push.enable : null,
                child: Text(push.busy ? 'Please wait…' : 'Enable notifications'),
              ),
              if (push.subscribed)
                OutlinedButton(
                  onPressed: push.busy ? null : push.disable,
                  child: const Text('Disable notifications'),
                ),
              TextButton(
                onPressed: push.busy ? null : push.init,
                child: const Text('Refresh status'),
              ),
            ]),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text('Contacts (${contacts.length})',
                style: Theme.of(context).textTheme.titleMedium),
          ),
          if (contacts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('No contacts yet. Invite someone to get started.'),
            )
          else
            ...contacts.map((contact) => _ContactTile(contact: contact)),
          const Divider(),
          ListTile(
            leading: Icon(Icons.delete_forever_outlined, color: Theme.of(context).colorScheme.error),
            title: Text(
              'Delete account',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            subtitle: const Text('Permanently removes your account and your messages'),
            onTap: () => confirmDeleteAccount(context),
          ),
          const Center(child: PrivacyPolicyLink()),
          const Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
            title: Text(
              'Sign out',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () async {
              final navigator = Navigator.of(context);
              // Best effort while the bearer still exists. Browser unsubscribe
              // also prevents alerts if the server cannot delete the record.
              await push.disable();
              try { await push.bridge.unsubscribe(); } catch (_) {}
              await state.signOut();
              if (navigator.canPop()) navigator.pop();
            },
          ),
          const ListTile(
            title: Text('Client build'),
            subtitle: SelectableText(String.fromEnvironment('BUILD_ID', defaultValue: 'dev')),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showProfileDialog(BuildContext context) => showProfileDialog(context);
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({required this.contact});

  final Contact contact;

  @override
  Widget build(BuildContext context) {
    final state = di<AppState>();
    final user = contact.user;
    return ListTile(
      leading: Avatar.user(
        user,
        size: 44,
        presence: state.presenceOf(user.id),
        resolveUrl: state.fileUrl,
      ),
      title: Text(user.displayName),
      subtitle: Text('@${user.username}'),
      trailing: IconButton(
        tooltip: 'Remove contact',
        icon: const Icon(Icons.person_remove_outlined),
        onPressed: () => state.removeContact(user.id),
      ),
    );
  }
}

/// Edits the display name, bio and accent colour.
Future<void> showProfileDialog(BuildContext context) async {
  final state = di<AppState>();
  if (state.me == null) return;
  final result = await showDialog<({String name, String bio})>(
    context: context,
    builder: (dialogContext) => const _ProfileDialog(),
  );
  if (result == null) return;
  await state.updateProfile(displayName: result.name, bio: result.bio);
}

/// Edits the display name, bio and picture.
///
/// A widget rather than a builder closure so it owns its controllers: disposing
/// them in the caller happens while the route is still animating out, and the
/// framework rebuilds the fields for those frames — which throws "A
/// TextEditingController was used after being disposed".
class _ProfileDialog extends StatefulWidget {
  const _ProfileDialog();

  @override
  State<_ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<_ProfileDialog> {
  late final TextEditingController _name;
  late final TextEditingController _bio;

  @override
  void initState() {
    super.initState();
    final me = di<AppState>().me;
    _name = TextEditingController(text: me?.displayName ?? '');
    _bio = TextEditingController(text: me?.bio ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = di<AppState>();
    final me = state.me;
    return AlertDialog(
      title: const Text('Edit profile'),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (me != null)
                Center(child: Avatar.user(me, size: 72, resolveUrl: state.fileUrl)),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
                TextButton.icon(
                  icon: const Icon(Icons.photo),
                  label: const Text('Upload picture'),
                  onPressed: () => _chooseProfilePhoto(context),
                ),
                TextButton(
                  onPressed: () => _useGravatar(context),
                  child: const Text('Use Gravatar'),
                ),
                TextButton(
                  onPressed: () => state.updateProfile(clearAvatar: true),
                  child: const Text('Remove picture'),
                ),
              ]),
              const SizedBox(height: 8),
              const Text(
                'Profile pictures are shared profile data, not encrypted chat attachments.',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bio,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'About'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
              context, (name: _name.text.trim(), bio: _bio.text.trim())),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

Future<void> _chooseProfilePhoto(BuildContext context) async {
  final state = di<AppState>();
  try {
    final file = await openFile(acceptedTypeGroups: [
      const XTypeGroup(label: 'Pictures', extensions: ['png', 'jpg', 'jpeg', 'webp'],
          mimeTypes: ['image/png', 'image/jpeg', 'image/webp']),
    ]);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (bytes.length > 2 * 1024 * 1024) throw StateError('Choose a picture smaller than 2 MB');
    final lower = file.name.toLowerCase();
    final type = file.mimeType ?? (lower.endsWith('.png') ? 'image/png' :
        lower.endsWith('.webp') ? 'image/webp' : 'image/jpeg');
    final uploaded = await state.backend.uploadAttachment(filename: file.name,
        contentType: type, data: bytes, encrypted: false);
    await state.updateProfile(avatarAttachmentId: uploaded.id);
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update picture: $error')));
    }
  }
}

Future<void> _useGravatar(BuildContext context) async {
  final state = di<AppState>();
  final controller = TextEditingController();
  final email = await showDialog<String>(context: context, builder: (dialogContext) => AlertDialog(
    title: const Text('Use Gravatar'),
    content: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('This contacts Gravatar with an email hash and your IP address. '
          'The downloaded picture is uploaded to Ratatosk; your email is not saved.'),
      TextField(controller: controller, decoration: const InputDecoration(labelText: 'Gravatar email')),
    ]),
    actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
      FilledButton(onPressed: () => Navigator.pop(dialogContext, controller.text), child: const Text('Import'))],
  ));
  controller.dispose();
  if (email == null) return;
  try {
    final bytes = await fetchGravatar(email);
    final uploaded = await state.backend.uploadAttachment(filename: 'gravatar.jpg',
        contentType: 'image/jpeg', data: bytes, encrypted: false);
    await state.updateProfile(avatarAttachmentId: uploaded.id);
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not import Gravatar: $error')));
    }
  }
}

/// Confirms and performs account deletion.
///
/// Two steps, because the action cannot be undone and there is no recovery: the
/// password is asked for (the server requires it too, and for the same reason — a
/// live session is not proof that the person at the keyboard owns the account),
/// and the button says what actually happens rather than "OK".
///
/// The wording is deliberately concrete about what is *not* deleted: a group's
/// history stays for the other members, because this store keeps messages
/// gapless and deleting from the middle would corrupt every client's cursor.
/// Promising "everything" and then keeping some of it would be a lie.
Future<void> confirmDeleteAccount(BuildContext context) async {
  final state = di<AppState>();
  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.maybeOf(context);

  final password = await showDialog<String>(
    context: context,
    builder: (dialogContext) => const _DeleteAccountDialog(),
  );
  if (password == null || password.isEmpty) return;

  final summary = await state.deleteAccount(password: password);
  if (summary == null) {
    // The server refused (a wrong password, or an unreachable server). The
    // session is still intact, so say what went wrong and leave the user signed
    // in rather than stranded.
    messenger?.showSnackBar(SnackBar(
      content: Text(state.lastError ?? 'Could not delete the account.'),
    ));
    return;
  }

  // Signed out by the manager; drop the settings screen with it.
  messenger?.showSnackBar(const SnackBar(
    content: Text('Your account has been deleted.'),
  ));
  if (navigator.canPop()) navigator.pop();
}

/// The confirmation, as a widget so it owns and disposes its own controller.
///
/// Disposing the controller in the caller does not work: `showDialog` returns
/// while the route is still animating out, and the framework keeps rebuilding the
/// TextField for those frames — which throws "A TextEditingController was used
/// after being disposed".
class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.pop(context, _controller.text);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete your account?'),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'This cannot be undone, and there is no way to recover the account '
                'or its messages afterwards.',
              ),
              const SizedBox(height: 12),
              const Text('It removes:'),
              const SizedBox(height: 4),
              const Text('\u2022 your account and profile\n'
                  '\u2022 every direct conversation you are part of, with its messages\n'
                  '\u2022 your uploaded files\n'
                  '\u2022 your devices and their encryption keys\n'
                  '\u2022 all sessions, so you are signed out everywhere'),
              const SizedBox(height: 12),
              const Text(
                // Promising "everything" and then keeping some of it would be a
                // lie: this store keeps messages gapless, so a group's history
                // stays for the members who remain.
                'Messages you sent in a group stay for the other members.',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                obscureText: true,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Your password',
                  helperText: 'Confirms it is really you',
                ),
                onSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Keep my account'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: _submit,
          child: const Text('Delete everything'),
        ),
      ],
    );
  }
}
