import 'package:flutter/material.dart';
import '../language.dart';
import 'package:watch_it/watch_it.dart';

import '../../crypto/manager.dart';
import '../../gen/ratatosk/v1/chat.pb.dart';
import '../../gen/ratatosk/v1/common.pb.dart';
import '../../state/app_state.dart';
import '../format.dart';
import '../theme.dart';
import 'avatar.dart';
import 'encrypted_image.dart';

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
  final void Function(DecryptedAttachment attachment)? onOpenImage;

  @override
  Widget build(BuildContext context) {
    final state = di<AppState>();
    final colors = RatatoskTheme.of(context);
    final message = entry.message;
    final isMine = message.senderId == state.me?.id;
    final scheme = Theme.of(context).colorScheme;
    // The plaintext, when this device can open it. A sealed message that cannot
    // be read yet shows why instead of an empty bubble.
    final body = state.bodyOf(entry);

    // A system note ("Ada added Grace") is a quiet centered line, not a bubble.
    if (message.kind == MessageKind.MESSAGE_KIND_SYSTEM) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 24),
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
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: message.deleted ? bubbleColor.withValues(alpha: 0.6) : bubbleColor,
        borderRadius: BorderRadius.only(
          topLeft: colors.bubbleRadius,
          topRight: colors.bubbleRadius,
          bottomLeft: isMine ? colors.bubbleRadius : Radius.circular(4),
          bottomRight: isMine ? Radius.circular(4) : colors.bubbleRadius,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showSender && !isMine && isGroup)
            Padding(
              padding: EdgeInsets.only(bottom: 2),
              child: Text(
                sender,
                style: TextStyle(
                  color: _senderColor(scheme, sender),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          if (!message.deleted && (message.hasReplyTo() || body.replyToText != null))
            _ReplyQuote(
              senderName: message.hasReplyTo() ? message.replyTo.senderName : '',
              text: body.replyToText ?? (message.hasReplyTo() ? message.replyTo.text : ''),
              deleted: message.hasReplyTo() && message.replyTo.deleted,
              onTap: onReply,
            ),
          if (message.deleted)
            Text(
              'You deleted this message',
              style: TextStyle(color: textColor.withValues(alpha: 0.85), fontStyle: FontStyle.italic),
            )
          else if (!body.ok) ...[
            // Sealed and not openable: the key may still be on its way.
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_clock, size: 14, color: textColor.withValues(alpha: 0.8)),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    body.unreadable ?? 'This message cannot be read',
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.9),
                      fontStyle: FontStyle.italic,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            if (body.attachments.isNotEmpty)
              _Attachments(
                attachments: body.attachments,
                resolveUrl: state.fileUrl,
                onOpenImage: onOpenImage,
              ),
            if (body.text.trim().isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: body.attachments.isEmpty ? 0 : 6),
                child: Text(body.text, style: TextStyle(color: textColor, fontSize: 15, height: 1.3)),
              ),
          ],
          SizedBox(height: 2),
          _Meta(
            time: ChatFormat.bubbleTime(message.createdAt.toDateTime(), use24Hour: state.use24Hour),
            edited: message.hasEditedAt() && !message.deleted,
            color: textColor.withValues(alpha: 0.7),
            showReceipt: isMine && isLastMine && !entry.isPending,
            seenBy: state.peerReadSeq(conversation) >= message.seq.toInt() && message.seq.toInt() > 0,
          ),
        ],
      ),
    );

    /// A display name for a user id, for the reaction tooltip.
    ///
    /// Falls back to "Someone" rather than an id: a name is what the tooltip is for,
    /// and an id string is worse than admitting we do not know who it was — somebody
    /// who left the conversation, or a member list that has not loaded.
    String reactionName(String userId) {
      if (userId == state.me?.id) return tr(context, 'You');
      for (final member in conversation.members) {
        if (member.user.id == userId) {
          final name = member.user.displayName;
          return name.isEmpty ? member.user.username : name;
        }
      }
      if (conversation.hasPeer() && conversation.peer.id == userId) {
        final peer = conversation.peer;
        return peer.displayName.isEmpty ? peer.username : peer.displayName;
      }
      return tr(context, 'Someone');
    }

    // Reactions overlap the bubble rather than sitting under it.
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
          // Sits *over* the bubble rather than below it, which is what makes a
          // reaction read as attached to the message instead of as the next item in
          // the list. A negative margin, not a Transform: translating moves the pixels
          // but leaves the layout box below the bubble, so the row still occupied its
          // own slot and the overlap was invisible in the spacing.
          // `Align(heightFactor:)` reserves *less* height than its child, and the
          // alignment puts the child's bottom on that reduced box — so the chips hang
          // upward over the bubble's lower edge while the column still moves on at the
          // reduced height.
          //
          // A negative padding is not allowed, and a Transform only moves pixels: the
          // layout box would stay below the bubble, so the overlap would be invisible
          // in the spacing even though the chip looked shifted.
          //
          // The alignment follows the bubble: a reaction belongs on the side its
          // message is on, so my own reactions sit right and the other person's sit
          // left. `bottomLeft` for everybody put every reaction on the left, which
          // reads as belonging to whoever spoke first.
          Align(
            alignment: isMine ? Alignment.bottomRight : Alignment.bottomLeft,
            heightFactor: 0.62,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: reactions
                    .map((reaction) => _ReactionChip(
                          reaction: reaction,
                          isMine: reaction.userIds.contains(state.me?.id),
                          onTap: () => onReact?.call(reaction.emoji),
                          resolveName: reactionName,
                        ))
                    .toList(),
              ),
            ),
          ),
        if (entry.state == SendState.failed)
          Padding(
            padding: EdgeInsets.only(top: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 14, color: scheme.error),
                SizedBox(width: 4),
                Text(tr(context, 'Not sent'), style: TextStyle(color: scheme.error, fontSize: 12)),
                TextButton(
                  onPressed: onRetry,
                  style: TextButton.styleFrom(
                    minimumSize: Size(0, 28),
                    padding: EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text(tr(context, 'Retry')),
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
                      padding: EdgeInsets.only(right: 4, bottom: 2),
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
      Color(0xFF1DA1F2),
      Color(0xFF17BF63),
      Color(0xFFF45D22),
      Color(0xFF794BC4),
      Color(0xFFE0245E),
      Color(0xFF00B7C2),
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
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: emojis
                    .map((emoji) => InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () {
                            // React first, then close. Doing it the other way
                            // round meant anything that went wrong while popping
                            // was swallowed and the tap looked like it did
                            // nothing at all.
                            //
                            // The trace is deliberate and cheap: a reaction that
                            // goes nowhere is otherwise indistinguishable from a
                            // tap that never arrived, and this line is what tells
                            // the two apart from the browser console.
                            debugPrint('[reaction] picked $emoji '
                                'handler=${onReact != null}');
                            onReact?.call(emoji);
                            Navigator.pop(sheetContext);
                          },
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: Text(emoji, style: TextStyle(fontSize: 26)),
                          ),
                        ))
                    .toList(),
              ),
            ),
            Divider(height: 1),
            ListTile(
              leading: Icon(Icons.reply),
              title: Text(tr(context, 'Reply')),
              onTap: () {
                Navigator.pop(sheetContext);
                onReply?.call();
              },
            ),
            if (canEdit)
              ListTile(
                leading: Icon(Icons.edit_outlined),
                title: Text(tr(context, 'Edit')),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onEdit?.call();
                },
              ),
            if (isMine && !entry.message.deleted && !entry.isPending)
              ListTile(
                leading: Icon(Icons.delete_outline),
                title: Text(tr(context, 'Delete')),
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

/// The quoted parent of a reply.
///
/// An encrypted conversation carries this inside the sealed body rather than in
/// the message record, so it is plain data by the time it gets here.
class _ReplyQuote extends StatelessWidget {
  const _ReplyQuote({
    required this.text,
    required this.deleted,
    this.senderName = '',
    this.onTap,
  });

  final String senderName;
  final String text;
  final bool deleted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = RatatoskTheme.of(context);
    final display = deleted ? 'Deleted message' : text;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 4),
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
              senderName.isEmpty ? 'Reply' : senderName,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: colors.timestamp),
            ),
            Text(
              display.isEmpty ? 'Attachment' : display,
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
///
/// Images are fetched and decrypted into memory rather than streamed by the
/// image widget: the bytes on the server are a client-side seal.
class _Attachments extends StatelessWidget {
  const _Attachments({
    required this.attachments,
    required this.resolveUrl,
    this.onOpenImage,
  });

  final List<DecryptedAttachment> attachments;
  final String Function(String path) resolveUrl;
  final void Function(DecryptedAttachment attachment)? onOpenImage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: attachments.map((attachment) {
        if (attachment.isImage) {
          return Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 260, maxWidth: 260),
                child: EncryptedImage(
                  attachment: attachment,
                  url: resolveUrl('/files/${attachment.blobId}'),
                  // The thumbnail is at most 260 logical pixels across; decoding
                  // the camera's full resolution for it is what makes a phone
                  // fail to draw the picture.
                  decodeWidth: (260 * MediaQuery.devicePixelRatioOf(context)).round(),
                  onTap: onOpenImage == null ? null : () => onOpenImage!(attachment),
                ),
              ),
            ),
          );
        }
        return _FileChip(attachment: attachment, url: resolveUrl('/files/${attachment.blobId}'));
      }).toList(),
    );
  }
}

class _FileChip extends StatelessWidget {
  const _FileChip({required this.attachment, required this.url});

  final DecryptedAttachment attachment;
  final String url;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 4),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insert_drive_file_outlined, size: 20),
          SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  attachment.filename,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                ),
                Text(
                  ChatFormat.fileSize(attachment.size),
                  style: TextStyle(fontSize: 11),
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
          SizedBox(width: 4),
        ],
        Text(time, style: TextStyle(fontSize: 11, color: color)),
        if (showReceipt) ...[
          SizedBox(width: 4),
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
  const _ReactionChip({
    required this.reaction,
    required this.isMine,
    required this.onTap,
    required this.resolveName,
  });

  final Reaction reaction;
  final bool isMine;
  final VoidCallback onTap;

  /// Turns a user id into a display name for the tooltip.
  final String Function(String userId) resolveName;

  /// Who reacted, as a sentence.
  ///
  /// The server sends ids, not names, so this reads them out of the conversation the
  /// bubble already has. Names are the whole point of the tooltip: "3" tells nobody
  /// anything, and an emoji alone cannot say whether it was the person you were
  /// talking to.
  String _whoReacted() {
    final names = reaction.userIds.map(resolveName).toList();
    if (names.isEmpty) return '';
    if (names.length == 1) return names.first;
    if (names.length <= 3) {
      return '${names.take(names.length - 1).join(', ')} and ${names.last}';
    }
    return '${names.take(2).join(', ')} and ${names.length - 2} others';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final count = reaction.userIds.length;
    final who = _whoReacted();
    return Tooltip(
      message: who.isEmpty ? reaction.emoji : '$who reacted ${reaction.emoji}',
      // Long-press already opens the message actions; a tooltip that swallowed it
      // would make the gesture stop working on a reacted message.
      triggerMode: TooltipTriggerMode.tap,
      waitDuration: const Duration(milliseconds: 400),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            // Opaque on purpose: the row overlaps the bubble, so a translucent chip
            // would show the message text through it.
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
              // The number appears once it counts *people* rather than restating the
              // emoji: "1" beside a 👍 says nothing the emoji did not, and it made the
              // commonest case the widest one.
              if (count > 1) ...[
                const SizedBox(width: 4),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isMine ? FontWeight.w600 : FontWeight.normal,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
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
      padding: EdgeInsets.symmetric(vertical: 12),
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
      padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
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
