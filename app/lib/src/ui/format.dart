import 'package:intl/intl.dart';

import '../gen/ratatosk/v1/chat.pb.dart';

/// Time and size formatting for the list and for message bubbles.
///
/// One place, so "9:41", "Yesterday" and "12 Mar" mean the same thing
/// everywhere in the app.
class ChatFormat {
  const ChatFormat._();

  /// A short stamp for a conversation list row.
  static String listTimestamp(DateTime? when, {bool? use24Hour}) {
    if (when == null) return '';
    final local = when.toLocal();
    final daysAgo = _daysAgo(local);
    if (daysAgo <= 0) return _time(local, use24Hour);
    if (daysAgo == 1) return 'Yesterday';
    if (daysAgo < 7) return DateFormat.E().format(local);
    if (local.year == DateTime.now().year) return DateFormat.MMMd().format(local);
    return DateFormat.yMd().format(local);
  }

  /// The time shown inside a bubble.
  static String bubbleTime(DateTime? when, {bool? use24Hour}) =>
      when == null ? '' : _time(when.toLocal(), use24Hour);

  static String _time(DateTime when, bool? use24Hour) =>
      (use24Hour == null ? DateFormat.jm() :
          use24Hour ? DateFormat.Hm() : DateFormat('h:mm a')).format(when);

  /// A day separator above the first message of a day.
  static String dayLabel(DateTime when) {
    final local = when.toLocal();
    final daysAgo = _daysAgo(local);
    if (daysAgo <= 0) return 'Today';
    if (daysAgo == 1) return 'Yesterday';
    if (daysAgo < 7) return DateFormat.EEEE().format(local);
    return DateFormat.yMMMMd().format(local);
  }

  /// "3.2 MB" for an attachment chip.
  static String fileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// A one-line summary of a conversation's last message.
  static String preview(Message? message) {
    if (message == null) return 'No messages yet';
    if (message.deleted) return 'This message was deleted';
    if (message.encrypted) return 'Encrypted message';
    if (message.kind == MessageKind.MESSAGE_KIND_SYSTEM) return message.text;
    final body = message.text.trim();
    if (message.attachments.isNotEmpty) {
      final label = message.attachments.length > 1
          ? '${message.attachments.length} attachments'
          : (message.attachments.first.isImage ? 'Photo' : message.attachments.first.filename);
      return body.isEmpty ? label : '$body · $label';
    }
    return body.isEmpty ? 'No messages yet' : body;
  }

  static int _daysAgo(DateTime local) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(local.year, local.month, local.day);
    return today.difference(that).inDays;
  }
}
