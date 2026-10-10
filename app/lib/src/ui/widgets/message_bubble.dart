import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../gen/ratatosk/v1/chat.pb.dart';
import '../../gen/ratatosk/v1/common.pb.dart';
import '../../state/app_state.dart';
import '../format.dart';
import '../theme.dart';
import 'avatar.dart';

/// One message, laid out the way a messenger does it: the reader's own messages
/// on the right in the accent colour, everyone else's on the left in grey, with
/// the sender's name above the first of a run in a group.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.entry,
    required this.conversation,
    required this.isGroup,
    required this.showSender,
    required this.showAvatar,
    required this.isLastMine,
    this.onReply,
    this.onEdit,
    this.onDelete,
    this.onReact,
    this.onRetry,
    this.onOpenImage,
  });

  final ChatMessage entry;
  final Conversation conversation;
  final bool isGroup;
  final bool showSender;
  final bool showAvatar;

  /// Whether this is the newest message the reader sent, which is where a read
  /// receipt belongs.
  final bool isLastMine;

  final VoidCallback? onReply;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final ValueChanged<String>? onReact;
  final VoidCallback? onRetry;
  final void Function(Attachment attachment)? onOpenImage;

  @override
  Widget build(BuildContext context) {
    final state = di<AppState>();
    final colors = RatatoskTheme.of(context);
    final message = entry.message;
    final isMine = message.senderId == state.me?.id;
    final scheme = Theme.of(context).colorScheme;

    // A system note ("Ada added Grace") is a quiet centered line, not a bubble.
    if (message.kind == MessageKind.MESSAGE_KIND_SYSTEM) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
        child: Text(
          message.text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.timestamp),
        ),
      );
    }

    final sender = _senderOf(message);
    final bubbleColor = isMine ? colors.ownBubble : colors.otherBubble;
    final textColor = isMine ? colors.ownText : colors.otherText;

    final bubble = Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.72),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: message.deleted ? bubbleColor.withValues(alpha: 0.6) : bubbleColor,
        borderRadius: BorderRadius.only(
          topLeft: colors.bubbleRadius,
          topRight: colors.bubbleRadius,
          bottomLeft: isMine ? colors.bubbleRadius : const Radius.circular(4),
          bottomRight: isMine ? const Radius.circular(4) : colors.bubbleRadius,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showSender && !isMine && isGroup)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                sender,
                style: TextStyle(
                  color: _senderColor(scheme, sender),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          if (message.hasReplyTo() && !message.deleted)
            _ReplyQuote(preview: message.replyTo, onTap: onReply),
          if (message.deleted)
            Text(
              'You deleted this message',
              style: TextStyle(color: textColor.withValues(alpha: 0.85), fontStyle: FontStyle.italic),
            )
          else ...[
            if (message.attachments.isNotEmpty)
              _Attachments(
                attachments: message.attachments,
                resolveUrl: state.fileUrl,
                onOpenImage: onOpenImage,
                onEdge: isMine,
              ),
            if (message.text.trim().isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: message.attachments.isEmpty ? 0 : 6),
                child: Text(message.text, style: TextStyle(color: textColor, fontSize: 15, height: 1.3)),
              ),
          ],
          const SizedBox(height: 2),
          _Meta(
            time: ChatFormat.bubbleTime(message.createdAt.toDateTime()),
            edited: message.hasEditedAt() && !message.deleted,
            color: textColor.withValues(alpha: 0.7),
            showReceipt: isMine && isLastMine && !entry.isPending,
            seenBy: state.peerReadSeq(conversation) >= message.seq.toInt() && message.seq.toInt() > 0,
          ),
        ],
      ),
    );

    // Reactions sit under the bubble, slightly overlapping it.
    final reactions = message.reactions.where((r) => r.userIds.isNotEmpty).toList();

    Widget content = Column(
      crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        // A long press is the messenger gesture for "act on this message"; on
        // desktop a right click does the same thing.
        GestureDetector(
          onLongPress: () => _showActions(context),
          onSecondaryTap: () => _showActions(context),
          child: bubble,
        ),
        if (reactions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
            child: Wrap(
              spacing: 4,
              children: reactions
                  .map((reaction) => _ReactionChip(
                        reaction: reaction,
                        isMine: reaction.userIds.contains(state.me?.id),
                        onTap: () => onReact?.call(reaction.emoji),
                      ))
                  .toList(),
            ),
          ),
        if (entry.state == SendState.failed)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 14, color: scheme.error),
                const SizedBox(width: 4),
                Text('Not sent', style: TextStyle(color: scheme.error, fontSize: 12)),
                TextButton(
                  onPressed: onRetry,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 28),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
      ],
    );

    return Padding(
      padding: EdgeInsets.only(top: showSender ? 10 : 2, left: 8, right: 8),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine)
            SizedBox(
              width: 36,
              child: showAvatar
                  ? Padding(
                      padding: const EdgeInsets.only(right: 4, bottom: 2),
                      child: Avatar.user(
                        _userOf(message),
                        size: 28,
                        resolveUrl: state.fileUrl,
                      ),
                    )
                  : null,
            ),
          Flexible(child: content),
        ],
      ),
    );
  }

  /// The sender as the conversation knows them.
  User _userOf(Message message) {
    for (final member in conversation.members) {
      if (member.user.id == message.senderId) return member.user;
    }
    return User(id: message.senderId, displayName: 'Unknown');
  }

  String _senderOf(Message message) {
    final user = _userOf(message);
    return user.displayName.isEmpty ? user.username : user.displayName;
  }

  /// A stable colour per sender, so names in a group are easy to tell apart.
  Color _senderColor(ColorScheme scheme, String name) {
    final palette = [
      const Color(0xFF1DA1F2),
      const Color(0xFF17BF63),
      const Color(0xFFF45D22),
      const Color(0xFF794BC4),
      const Color(0xFFE0245E),
      const Color(0xFF00B7C2),
    ];
    return palette[name.hashCode.abs() % palette.length];
  }

  void _showActions(BuildContext context) {
    final state = di<AppState>();
    final isMine = entry.message.senderId == state.me?.id;
    final canEdit = isMine && !entry.message.deleted && !entry.isPending;
    const emojis = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: emojis
                    .map((emoji) => InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () {
                            Navigator.pop(sheetContext);
                            onReact?.call(emoji);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(emoji, style: const TextStyle(fontSize: 26)),
                          ),
                        ))
                    .toList(),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(sheetContext);
                onReply?.call();
              },
            ),
            if (canEdit)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onEdit?.call();
                },
              ),
            if (isMine && !entry.message.deleted && !entry.isPending)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Delete'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onDelete?.call();
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// The quoted parent of a reply, tapping it is a jump-to in a real messenger;
/// here it just closes back to the thread.
class _ReplyQuote extends StatelessWidget {
  const _ReplyQuote({required this.preview, this.onTap});

  final ReplyPreview preview;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = RatatoskTheme.of(context);
    final text = preview.deleted ? 'Deleted message' : preview.text;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(color: colors.timestamp.withValues(alpha: 0.6), width: 3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              preview.senderName.isEmpty ? 'Reply' : preview.senderName,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: colors.timestamp),
            ),
            Text(
              preview.hasAttachment && text.isEmpty ? 'Attachment' : text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: colors.timestamp),
            ),
          ],
        ),
      ),
    );
  }
}

/// Attachment thumbnails and file chips inside a bubble.
class _Attachments extends StatelessWidget {
  const _Attachments({
    required this.attachments,
    required this.resolveUrl,
    this.onOpenImage,
    required this.onEdge,
  });

  final List<Attachment> attachments;
  final String Function(String path) resolveUrl;
  final void Function(Attachment attachment)? onOpenImage;
  final bool onEdge;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: attachments.map((attachment) {
        if (attachment.isImage) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: GestureDetector(
              onTap: () => onOpenImage?.call(attachment),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 260, maxWidth: 260),
                  child: Image.network(
                    resolveUrl(attachment.url),
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) => progress == null
                        ? child
                        : const SizedBox(
                            height: 120,
                            width: 120,
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                    errorBuilder: (context, _, __) => Container(
                      height: 120,
                      width: 160,
                      color: Colors.black.withValues(alpha: 0.15),
                      child: const Center(child: Icon(Icons.broken_image_outlined)),
                    ),
                  ),
                ),
              ),
            ),
          );
        }
        return _FileChip(attachment: attachment, url: resolveUrl(attachment.url));
      }).toList(),
    );
  }
}

class _FileChip extends StatelessWidget {
  const _FileChip({required this.attachment, required this.url});

  final Attachment attachment;
  final String url;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.insert_drive_file_outlined, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  attachment.filename,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                ),
                Text(
                  ChatFormat.fileSize(attachment.size.toInt()),
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The timestamp and, for the reader's own newest message, whether it has been
/// read.
class _Meta extends StatelessWidget {
  const _Meta({
    required this.time,
    required this.edited,
    required this.color,
    required this.showReceipt,
    required this.seenBy,
  });

  final String time;
  final bool edited;
  final Color color;
  final bool showReceipt;
  final bool seenBy;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (edited) ...[
          Text('edited', style: TextStyle(fontSize: 11, color: color)),
          const SizedBox(width: 4),
        ],
        Text(time, style: TextStyle(fontSize: 11, color: color)),
        if (showReceipt) ...[
          const SizedBox(width: 4),
          Icon(
            seenBy ? Icons.done_all : Icons.done,
            size: 14,
            color: seenBy ? color : color.withValues(alpha: 0.6),
          ),
        ],
      ],
    );
  }
}

class _ReactionChip extends StatelessWidget {
  const _ReactionChip({required this.reaction, required this.isMine, required this.onTap});

  final Reaction reaction;
  final bool isMine;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isMine ? scheme.primaryContainer : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isMine ? scheme.primary : scheme.outlineVariant,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(reaction.emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 3),
            if (reaction.userIds.length > 1)
              Text('${reaction.userIds.length}', style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

/// A day separator between messages from different days.
class DayDivider extends StatelessWidget {
  const DayDivider({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: RatatoskTheme.of(context).timestamp,
              ),
        ),
      ),
    );
  }
}

/// A soft "Seen" line, shown under the thread when the other person has read
/// everything.
class SeenLabel extends StatelessWidget {
  const SeenLabel({super.key, required this.seen});

  final bool seen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          seen ? 'Seen' : 'Sent',
          style: TextStyle(fontSize: 11, color: RatatoskTheme.of(context).timestamp),
        ),
      ),
    );
  }
}
