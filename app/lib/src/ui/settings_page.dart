import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../api/backend.dart';
import '../gen/ratatosk/v1/social.pb.dart';
import '../state/app_state.dart';
import '../notifications/manager.dart';
import 'auth_screen.dart';
import 'theme.dart';
import 'widgets/avatar.dart';

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
  final me = state.me;
  if (me == null) return;
  final nameController = TextEditingController(text: me.displayName);
  final bioController = TextEditingController(text: me.bio);
  final selected = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Edit profile'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: bioController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'About'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(context, nameController.text.trim()),
          child: const Text('Save'),
        ),
      ],
    ),
  );
  final bio = bioController.text.trim();
  nameController.dispose();
  bioController.dispose();
  if (selected == null) return;
  await state.updateProfile(displayName: selected, bio: bio);
}
