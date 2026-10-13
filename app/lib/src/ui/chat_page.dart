import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../crypto/manager.dart';
import '../gen/ratatosk/v1/chat.pb.dart';
import '../gen/ratatosk/v1/common.pb.dart';
import '../state/app_state.dart';
import 'conversation_details_page.dart';
import 'encryption_sheet.dart';
import 'format.dart';
import 'theme.dart';
import 'widgets/avatar.dart';
import 'widgets/composer.dart';
import 'widgets/encrypted_image.dart';
import 'widgets/message_bubble.dart';

/// One conversation: the message thread, its header and the composer.
///
/// The list is a reversed `ListView` (newest at the bottom, index 0 at the
/// bottom of the screen), which is what makes "scroll up for older messages"
/// and "stick to the bottom when a new message arrives" both behave the way
/// people expect.
class ChatPage extends WatchingStatefulWidget {
  const ChatPage({super.key, required this.conversationId});

  final String conversationId;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _scroll = ScrollController();
  Message? _replyTo;
  Message? _editing;

  /// The last error already shown, so a rebuild does not repeat it.
  String? _reportedError;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    // Opening the conversation is what triggers the history fetch and the read
    // cursor; it is deferred to after the frame so the list is on screen first.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      di<AppState>().openConversation(widget.conversationId);
    });
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    // "Scroll up" in a reversed list means the offset grows towards the top.
    if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 200) {
      di<AppState>().loadOlder(widget.conversationId);
    }
  }

  @override
  Widget build(BuildContext context) {
    // One watch for the whole thread: the manager is the single source of
    // truth, so any change (a new message, a read receipt, typing) rebuilds
    // this page. watch_it requires watch calls in build, in a fixed order.
    final state = watchIt<AppState>();
    // Report a failed action (a reaction, an edit, a delete) instead of swallowing
    // it. `lastError` was recorded by the manager and displayed on no screen but the
    // sign-in one, so a request the server refused looked exactly like a tap that
    // did nothing.
    //
    // The error is *reported*, not consumed: other screens and callers read
    // `lastError`, so clearing it here would hide it from them. Tracking the last
    // one shown keeps a rebuild from repeating the same snackbar.
    final error = state.lastError;
    if (error != null && error != _reportedError) {
      _reportedError = error;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(error)));
      });
    }
    final conversation = state.conversation(widget.conversationId);
    final messages = state.messages(widget.conversationId);
    final typing = state.typingIn(widget.conversationId);
    final isGroup = conversation?.kind == 'group';

    if (conversation == null) {
      // The conversation can vanish while it is open (removed, or the list has
      // not caught up yet); an empty placeholder beats a crash.
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: _header(context, state, conversation),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty && state.historyLoaded(widget.conversationId)
                ? _EmptyThread(conversation: conversation)
                : _thread(context, state, conversation, messages, isGroup),
          ),
          if (typing.isNotEmpty) _TypingRow(names: typing.map((t) => t.displayName).toList()),
          Composer(
            conversationId: widget.conversationId,
            replyTo: _replyTo,
            editing: _editing,
            onCancelReply: () => setState(() => _replyTo = null),
            onCancelEdit: () => setState(() => _editing = null),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _header(BuildContext context, AppState state, Conversation conversation) {
    final peer = state.peerOf(conversation);
    final subtitle = _subtitle(state, conversation);
    return AppBar(
      titleSpacing: 12,
      title: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ConversationDetailsPage(conversationId: conversation.id),
          ),
        ),
        child: Row(
          children: [
            if (peer != null)
              Avatar.user(
                peer,
                size: 36,
                presence: state.presenceOf(peer.id),
                resolveUrl: state.fileUrl,
              )
            else
              Avatar(
                name: state.titleOf(conversation),
                imageUrl: conversation.avatarUrl.isEmpty ? null : state.fileUrl(conversation.avatarUrl),
                color: conversation.accentColor,
                id: conversation.id,
                size: 36,
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    state.titleOf(conversation),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: RatatoskTheme.of(context).timestamp),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        EncryptionBadge(
          verified: state.isVerified(conversation.id),
          canEncrypt: state.canEncryptConversation(conversation.id),
          onTap: () => showEncryptionSheet(context, conversation.id),
        ),
        IconButton(
          tooltip: conversation.muted ? 'Unmute' : 'Mute',
          icon: Icon(conversation.muted ? Icons.notifications_off : Icons.notifications_none),
          onPressed: () => state.setConversationFlags(conversation.id, muted: !conversation.muted),
        ),
        IconButton(
          tooltip: conversation.pinned ? 'Unpin' : 'Pin',
          icon: Icon(conversation.pinned ? Icons.push_pin : Icons.push_pin_outlined),
          onPressed: () => state.setConversationFlags(conversation.id, pinned: !conversation.pinned),
        ),
      ],
    );
  }

  /// Under the title: presence for a person, member count for a group.
  String _subtitle(AppState state, Conversation conversation) {
    if (conversation.kind == 'group') {
      final others = state.otherMembers(conversation);
      final names = others.map((u) => u.displayName).take(3).join(', ');
      final rest = others.length - 3;
      if (names.isEmpty) return '${conversation.members.length} members';
      return rest > 0 ? '$names and $rest more' : names;
    }
    final peer = state.peerOf(conversation);
    if (peer == null) return '';
    switch (state.presenceOf(peer.id)) {
      case Presence.PRESENCE_ONLINE:
        return 'Active now';
      case Presence.PRESENCE_AWAY:
        return 'Away';
      default:
        if (peer.hasLastSeen()) {
          return 'Last seen ${ChatFormat.listTimestamp(peer.lastSeen.toDateTime(), use24Hour: di<AppState>().use24Hour)}';
        }
        return '';
    }
  }

  Widget _thread(
    BuildContext context,
    AppState state,
    Conversation conversation,
    List<ChatMessage> messages,
    bool isGroup,
  ) {
    // Rendered newest-first, so the reversed list keeps the newest at the
    // bottom and appends older messages as the user scrolls up.
    final ordered = messages.reversed.toList();
    final showSeen = messages.isNotEmpty && messages.last.message.senderId == state.me?.id;

    return ListView.builder(
      controller: _scroll,
      reverse: true,
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      itemCount: ordered.length + (state.hasOlder(conversation.id) ? 1 : 0) + (showSeen ? 1 : 0),
      itemBuilder: (context, index) {
        var cursor = index;
        if (showSeen) {
          if (cursor == 0) {
            return SeenLabel(seen: state.peerReadSeq(conversation) >= messages.last.seq);
          }
          cursor -= 1;
        }
        if (state.hasOlder(conversation.id) && cursor == ordered.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        final entry = ordered[cursor];
        // The next item in the reversed list is the *older* neighbour, which is
        // what decides whether this is the first message of a run.
        final olderNeighbour = cursor + 1 < ordered.length ? ordered[cursor + 1] : null;
        final dayLabel = _dayLabelIfNeeded(entry, olderNeighbour);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (dayLabel != null) DayDivider(label: dayLabel),
            MessageBubble(
              entry: entry,
              conversation: conversation,
              isGroup: isGroup,
              showSender: olderNeighbour == null ||
                  olderNeighbour.message.senderId != entry.message.senderId ||
                  dayLabel != null,
              showAvatar: olderNeighbour == null ||
                  olderNeighbour.message.senderId != entry.message.senderId,
              isLastMine: entry.message.id == messages.last.id,
              onReply: () => setState(() {
                _editing = null;
                _replyTo = entry.message;
              }),
              onEdit: () => setState(() {
                _replyTo = null;
                _editing = entry.message;
              }),
              onDelete: () => state.deleteMessage(conversation.id, entry.message.id),
              onReact: (emoji) => state.toggleReaction(conversation.id, entry.message, emoji),
              onRetry: () => state.retry(conversation.id, entry.id),
              onOpenImage: (attachment) => _viewImage(context, state, attachment),
            ),
          ],
        );
      },
    );
  }

  /// A "Today" / "Yesterday" divider whenever the day changes.
  String? _dayLabelIfNeeded(ChatMessage entry, ChatMessage? olderNeighbour) {
    final created = entry.message.createdAt.toDateTime();
    if (olderNeighbour == null) return ChatFormat.dayLabel(created);
    final older = olderNeighbour.message.createdAt.toDateTime();
    final sameDay = created.toLocal().year == older.toLocal().year &&
        created.toLocal().month == older.toLocal().month &&
        created.toLocal().day == older.toLocal().day;
    return sameDay ? null : ChatFormat.dayLabel(created);
  }

  /// Opens one image full screen. The bytes are decrypted into memory first,
  /// because what the server holds is ciphertext.
  void _viewImage(BuildContext context, AppState state, DecryptedAttachment attachment) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
          body: Center(
            child: InteractiveViewer(
              child: EncryptedImage(
                attachment: attachment,
                url: state.fileUrl('/files/${attachment.blobId}'),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyThread extends StatelessWidget {
  const _EmptyThread({required this.conversation});

  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 48, color: RatatoskTheme.of(context).timestamp),
            const SizedBox(height: 12),
            Text(
              'No messages yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              conversation.kind == 'group'
                  ? 'Say hello to the group.'
                  : 'Say hello — this is the start of your conversation.',
              textAlign: TextAlign.center,
              style: TextStyle(color: RatatoskTheme.of(context).timestamp),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Ada is typing…" with the standard three bouncing dots would need an
/// animation controller for little gain; the names alone read clearly.
class _TypingRow extends StatelessWidget {
  const _TypingRow({required this.names});

  final List<String> names;

  @override
  Widget build(BuildContext context) {
    final label = names.length == 1
        ? '${names.first} is typing…'
        : '${names.take(2).join(', ')} are typing…';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: RatatoskTheme.of(context).timestamp),
      ),
    );
  }
}
