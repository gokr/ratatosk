import 'package:flutter/material.dart';
import 'language.dart';
import 'package:watch_it/watch_it.dart';

import '../state/app_state.dart';
import 'new_chat_sheet.dart';
import 'theme.dart';
import 'widgets/avatar.dart';

/// Who is in this conversation, and the actions that change that: rename a
/// group, add people, leave, mute, pin.
class ConversationDetailsPage extends WatchingWidget {
  const ConversationDetailsPage({super.key, required this.conversationId});

  final String conversationId;

  @override
  Widget build(BuildContext context) {
    final state = watchIt<AppState>();
    final conversation = state.conversation(conversationId);
    if (conversation == null) {
      return Scaffold(body: Center(child: Text(tr(context, 'This conversation is gone.'))));
    }
    final isGroup = conversation.kind == 'group';
    final me = state.me;

    return Scaffold(
      appBar: AppBar(title: Text(tr(context, 'Details'))),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Avatar(
                  name: state.titleOf(conversation),
                  imageUrl: conversation.avatarUrl.isEmpty
                      ? null
                      : state.fileUrl(conversation.avatarUrl),
                  color: conversation.accentColor,
                  id: conversation.id,
                  size: 96,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        state.titleOf(conversation),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    if (isGroup)
                      IconButton(
                        tooltip: tr(context, 'Rename'),
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: () => _rename(context),
                      ),
                  ],
                ),
                Text(
                  conversation.kind == 'group'
                      ? 'Group · ${conversation.members.length} members'
                      : 'Direct conversation',
                  style: TextStyle(color: RatatoskTheme.of(context).timestamp),
                ),
              ],
            ),
          ),
          const Divider(),
          SwitchListTile(
            secondary: Icon(conversation.muted ? Icons.notifications_off : Icons.notifications_none),
            title: Text(tr(context, 'Muted')),
            value: conversation.muted,
            onChanged: (value) => state.setConversationFlags(conversation.id, muted: value),
          ),
          SwitchListTile(
            secondary: Icon(conversation.pinned ? Icons.push_pin : Icons.push_pin_outlined),
            title: Text(tr(context, 'Pinned')),
            subtitle: Text(tr(context, 'Pinned conversations stay at the top of the list')),
            value: conversation.pinned,
            onChanged: (value) => state.setConversationFlags(conversation.id, pinned: value),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(tr(context, 'Members'), style: Theme.of(context).textTheme.titleMedium),
          ),
          ...conversation.members.map((member) {
            final isMe = member.user.id == me?.id;
            final isOwner = member.role == 'owner';
            return ListTile(
              leading: Avatar.user(
                member.user,
                size: 44,
                presence: state.presenceOf(member.user.id),
                resolveUrl: state.fileUrl,
              ),
              title: Row(
                children: [
                  Flexible(
                    child: Text(isMe ? '${member.user.displayName} (you)' : member.user.displayName),
                  ),
                  if (isOwner)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Chip(
                        label: Text(tr(context, 'owner'), style: TextStyle(fontSize: 10)),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                ],
              ),
              subtitle: Text('@${member.user.username}'),
              trailing: isGroup && !isMe
                  ? IconButton(
                      tooltip: tr(context, 'Remove from group'),
                      icon: const Icon(Icons.person_remove_outlined),
                      onPressed: () => _remove(context, member.user.displayName, member.user.id),
                    )
                  : null,
              onTap: isMe
                  ? null
                  : () => state.startDirectChat(userId: member.user.id),
            );
          }),
          if (isGroup)
            ListTile(
              leading: const Icon(Icons.person_add_alt),
              title: Text(tr(context, 'Add members')),
              onTap: () => _addMembers(context),
            ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
            title: Text(
              isGroup ? 'Leave group' : 'Close',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () => _leave(context, isGroup),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _rename(BuildContext context) async {
    final state = di<AppState>();
    final conversation = state.conversation(conversationId);
    if (conversation == null) return;
    final controller = TextEditingController(text: conversation.title);
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(context, 'Group name')),
        content: TextField(controller: controller, autofocus: true),
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
    if (title == null || title.isEmpty) return;
    await state.renameConversation(conversationId, title);
  }

  Future<void> _addMembers(BuildContext context) async {
    final state = di<AppState>();
    final controller = TextEditingController();
    final username = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(context, 'Add someone')),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: tr(context, 'Username')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(tr(context, 'Cancel'))),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(tr(context, 'Add')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (username == null || username.isEmpty) return;
    await state.addMembers(conversationId, [username]);
  }

  Future<void> _remove(BuildContext context, String name, String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(trp(context, 'Remove {0}?', [name])),
        content: Text(tr(context, 'They keep their copy of the messages they already saw.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr(context, 'Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(tr(context, 'Remove'))),
        ],
      ),
    );
    if (confirmed != true) return;
    await di<AppState>().removeMember(conversationId, userId: userId);
  }

  Future<void> _leave(BuildContext context, bool isGroup) async {
    final state = di<AppState>();
    final navigator = Navigator.of(context);
    if (isGroup) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(tr(context, 'Leave this group?')),
          content: Text(tr(context, 'You will stop receiving its messages.')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr(context, 'Cancel'))),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(tr(context, 'Leave'))),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    await state.leaveConversation(conversationId);
    navigator.pop();
  }
}

/// Re-exported so the details page and the new-chat sheet agree on one entry
/// point for starting a chat.
Future<void> startChatWith(BuildContext context, String userId) async {
  final state = di<AppState>();
  final conversation = await state.startDirectChat(userId: userId);
  if (conversation == null || !context.mounted) return;
  await showNewChatSheet(context);
}
