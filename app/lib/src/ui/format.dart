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
    if (daysAgo == 1) return Intl.getCurrentLocale().startsWith('sv') ? 'Igår' : 'Yesterday';
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

  /// When something *expires*, which is the opposite direction from every other
  /// timestamp here.
  ///
  /// `listTimestamp` answers "when did this happen" and degrades badly on a future
  /// date: the day difference goes negative, it falls into the "today" branch, and it
  /// returns a bare time of day. An invite expiring next week then read as "9:41 PM",
  /// which looks like it has already passed — which is exactly how a list of perfectly
  /// valid links came to look expired.
  ///
  /// So this says how far away it is *and* the date, because "in 7 days" is readable
  /// at a glance and "21 Oct" is checkable.
  static String expiry(DateTime? when) {
    if (when == null) return 'never expires';
    final local = when.toLocal();
    final remaining = local.difference(DateTime.now());
    if (remaining.isNegative) {
      final ago = -remaining;
      if (ago.inMinutes < 1) return 'expired just now';
      if (ago.inHours < 1) return 'expired ${ago.inMinutes} min ago';
      if (ago.inDays < 1) return 'expired ${ago.inHours} h ago';
      if (ago.inDays == 1) return 'expired yesterday';
      return 'expired ${ago.inDays} days ago';
    }
    final time = _time(local, null);
    if (remaining.inMinutes < 60) return 'expires in ${remaining.inMinutes} min (at $time)';
    // Decided by calendar day, not by elapsed hours. "24 hours from now" is tomorrow,
    // and comparing whole hours first called it today — a boundary a person does not
    // think in.
    switch (_daysAhead(local)) {
      case 0:
        return 'expires today at $time';
      case 1:
        return 'expires tomorrow at $time';
      case < 7:
        return 'expires ${DateFormat.EEEE().format(local)} at $time';
    }
    return 'expires ${DateFormat.yMMMd().format(local)}';
  }

  static int _daysAhead(DateTime local) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(local.year, local.month, local.day);
    return that.difference(today).inDays;
  }

  /// A day separator above the first message of a day.
  static String dayLabel(DateTime when) {
    final local = when.toLocal();
    final daysAgo = _daysAgo(local);
    if (daysAgo <= 0) return Intl.getCurrentLocale().startsWith('sv') ? 'Idag' : 'Today';
    if (daysAgo == 1) return Intl.getCurrentLocale().startsWith('sv') ? 'Igår' : 'Yesterday';
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
