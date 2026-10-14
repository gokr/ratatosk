import 'package:flutter/material.dart';
import 'language.dart';
import 'package:watch_it/watch_it.dart';

import '../gen/ratatosk/v1/chat.pb.dart';
import '../state/app_state.dart';
import '../session_store.dart';
import 'widgets/recovery_prompt.dart';
import 'chat_page.dart';
import 'format.dart';
import 'invite_sheet.dart';
import 'new_chat_sheet.dart';
import 'settings_page.dart';
import 'theme.dart';
import 'widgets/avatar.dart';
import 'widgets/brand_logo.dart';

/// The list of conversations: the app's home screen.
/// Guards the one-time recovery offer so a rebuild does not re-schedule it. The
/// persisted flag in SessionStore is what stops it returning on the next launch.
bool _recoveryOfferScheduled = false;

class ChatListPage extends WatchingWidget {
  const ChatListPage({super.key, this.selectedConversationId, this.onSelect});

  /// Highlighted as the open thread when the layout shows both panes.
  final String? selectedConversationId;

  /// Called when a row is tapped. On narrow layouts this pushes the chat page;
  /// on wide ones the shell just changes the right-hand pane.
  final void Function(String conversationId)? onSelect;

  @override
  Widget build(BuildContext context) {
    final state = watchIt<AppState>();
    // Offered once, after the first frame so a dialog is not pushed mid-build.
    if (!_recoveryOfferScheduled && state.me != null) {
      _recoveryOfferScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        maybeOfferKeyRecovery(context, state, di<SessionStore>());
      });
    }
    final ids = state.conversationIds;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            BrandLogo(size: 32),
            SizedBox(width: 10),
            Text(tr(context, 'Chats'), style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          if (!state.realtimeConnected)
            Padding(
              padding: EdgeInsets.only(right: 4),
              child: Tooltip(
                message: 'Reconnecting…',
                child: Icon(
                  Icons.cloud_off,
                  size: 18,
                  color: RatatoskTheme.of(context).timestamp,
                ),
              ),
            ),
          IconButton(
            tooltip: tr(context, 'Invite someone'),
            icon: Icon(Icons.person_add_alt),
            onPressed: () => showInviteSheet(context),
          ),
          IconButton(
            tooltip: tr(context, 'Settings'),
            icon: Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => SettingsPage()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showNewChatSheet(context),
        tooltip: tr(context, 'New conversation'),
        child: Icon(Icons.edit_outlined),
      ),
      body: RefreshIndicator(
        onRefresh: state.refresh,
        child: ids.isEmpty
            ? _EmptyList(onStart: () => showNewChatSheet(context))
            : ListView.separated(
                itemCount: ids.length,
                separatorBuilder: (_, __) => Divider(height: 1),
                itemBuilder: (context, index) {
                  final id = ids[index];
                  final conversation = state.conversation(id);
                  if (conversation == null) return SizedBox.shrink();
                  return _ConversationTile(
                    conversation: conversation,
                    selected: id == selectedConversationId,
                    onTap: () {
                      if (onSelect != null) {
                        onSelect!(id);
                      } else {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => ChatPage(conversationId: id)),
                        );
                      }
                    },
                  );
                },
              ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.selected,
    required this.onTap,
  });

  final Conversation conversation;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final state = di<AppState>();
    final scheme = Theme.of(context).colorScheme;
    final peer = state.peerOf(conversation);
    final last = conversation.hasLastMessage() ? conversation.lastMessage : null;
    final opened = last == null || last.deleted ? null : state.previewBody(last);
    final preview = opened != null && opened.ok
        ? (opened.text.trim().isNotEmpty ? opened.text.trim()
            : opened.attachments.isNotEmpty ? 'Photo or attachment' : 'Message')
        : ChatFormat.preview(last);
    final unread = conversation.unreadCount;
    final isUnread = unread > 0;
    final lastMine = conversation.hasLastMessage() && conversation.lastMessage.senderId == state.me?.id;

    return Material(
      color: selected ? scheme.primaryContainer.withValues(alpha: 0.4) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              if (peer != null)
                Avatar.user(
                  peer,
                  size: 52,
                  presence: state.presenceOf(peer.id),
                  resolveUrl: state.fileUrl,
                )
              else
                Avatar(
                  name: state.titleOf(conversation),
                  imageUrl: conversation.avatarUrl.isEmpty
                      ? null
                      : state.fileUrl(conversation.avatarUrl),
                  color: conversation.accentColor,
                  id: conversation.id,
                  size: 52,
                ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (conversation.pinned)
                          Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(Icons.push_pin, size: 13, color: RatatoskTheme.of(context).timestamp),
                          ),
                        Expanded(
                          child: Text(
                            state.titleOf(conversation),
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          ChatFormat.listTimestamp(
                            conversation.hasLastMessage()
                                ? conversation.lastMessage.createdAt.toDateTime()
                                : conversation.createdAt.toDateTime(),
                            use24Hour: state.use24Hour,
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: isUnread ? scheme.primary : RatatoskTheme.of(context).timestamp,
                            fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2),
                    Row(
                      children: [
                        if (lastMine && conversation.hasLastMessage() && !conversation.lastMessage.deleted)
                          Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(
                              Icons.done_all,
                              size: 15,
                              color: isUnread ? scheme.primary : RatatoskTheme.of(context).timestamp,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            preview,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              color: isUnread
                                  ? scheme.onSurface
                                  : RatatoskTheme.of(context).timestamp,
                              fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (conversation.muted)
                          Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(
                              Icons.notifications_off,
                              size: 14,
                              color: RatatoskTheme.of(context).timestamp,
                            ),
                          ),
                        if (isUnread)
                          Container(
                            margin: EdgeInsets.only(left: 6),
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            constraints: BoxConstraints(minWidth: 20),
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$unread',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyList extends StatelessWidget {
  const _EmptyList({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: constraints.maxHeight,
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.forum_outlined, size: 56, color: RatatoskTheme.of(context).timestamp),
                  SizedBox(height: 16),
                  Text(tr(context, 'No conversations yet'), style: Theme.of(context).textTheme.titleMedium),
                  SizedBox(height: 8),
                  Text(
                    tr(context, 'Start a chat with someone, or send them an invitation link.'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: RatatoskTheme.of(context).timestamp),
                  ),
                  SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: onStart,
                    icon: Icon(Icons.add_comment_outlined),
                    label: Text(tr(context, 'New conversation')),
                  ),
                  SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => showInviteSheet(context),
                    icon: Icon(Icons.link),
                    label: Text(tr(context, 'Create an invitation link')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
