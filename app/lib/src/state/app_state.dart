import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart';

import '../api/backend.dart';
import '../crypto/crypto.dart';
import '../crypto/manager.dart';
import '../crypto/message_content.dart';
import '../gen/ratatosk/v1/chat.pb.dart';
import '../gen/ratatosk/v1/common.pb.dart';
import '../gen/ratatosk/v1/social.pb.dart';

/// A file the user picked, before it is sealed and uploaded. The bytes are
/// already in memory, so sealing them costs nothing extra.
typedef AttachmentUpload = ({String filename, String contentType, Uint8List bytes});

/// How far a message has got on its way to the server.
enum SendState {
  /// Stored on the server.
  sent,

  /// Shown optimistically; the round trip is still in flight.
  sending,

  /// The send failed. The bubble stays visible so the text is not lost.
  failed,
}

/// A message plus the local state the wire has no room for.
@immutable
class ChatMessage {
  const ChatMessage(this.message, {this.state = SendState.sent, this.error});

  final Message message;
  final SendState state;
  final String? error;

  String get id => message.id;
  int get seq => message.seq.toInt();
  bool get isPending => state != SendState.sent;

  ChatMessage copyWith({Message? message, SendState? state, String? error}) => ChatMessage(
        message ?? this.message,
        state: state ?? this.state,
        error: error ?? this.error,
      );
}

/// "Someone is typing", with the moment it stops being believable. The timer
/// matters: a client that vanishes mid-sentence must not leave an indicator
/// blinking forever.
class TypingIndicator {
  TypingIndicator(this.userId, this.displayName, this.until);

  final String userId;
  final String displayName;

  /// When this indicator stops being believable.
  final DateTime until;

  bool expiredAt(DateTime now) => now.isAfter(until);
}

/// The signed-in user's session and everything on screen.
///
/// One object owns the client-side state: the conversation list, the message
/// history per conversation, typing indicators, presence and the realtime
/// subscription. The UI reads it and calls methods on it, so no second copy can
/// drift.
///
/// Two rules hold throughout:
///
///  * The server is authoritative. Local sends are optimistic echoes that the
///    stored message replaces, matched by `clientMessageId`; edits, deletes and
///    reactions are replaced by the message the server returns.
///  * A dropped realtime stream is invisible to the user: the app reconnects
///    and catches up from the store. A chat client that quietly stops updating
///    is worse than one that reloads slightly more than it had to.
class AppState extends ChangeNotifier {
  AppState({
    required this.backend,
    required this.crypto,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final ChatBackend backend;

  /// End-to-end encryption: keys, sender keys and the decrypted message cache.
  final CryptoManager crypto;

  /// The clock the manager reads. Injectable so tests can advance time without
  /// waiting; every expiry decision goes through it.
  final DateTime Function() _clock;

  /// How long a remote typing indicator stays on screen without a refresh.
  /// Slightly longer than the server's own expiry so the two agree.
  static const typingLifetime = Duration(seconds: 7);

  /// How often the app re-announces that the user is still typing.
  static const typingRefresh = Duration(seconds: 3);

  // --- session -----------------------------------------------------------

  bool _bootstrapping = true;
  bool _signedIn = false;
  User? _me;
  String? _lastError;
  String? _token;
  void Function(String token) _persistToken = _ignoreToken;

  bool get bootstrapping => _bootstrapping;
  bool get signedIn => _signedIn;
  User? get me => _me;
  String? get lastError => _lastError;

  void clearError() {
    if (_lastError == null) return;
    _lastError = null;
    _notify();
  }

  static void _ignoreToken(String _) {}

  /// Restores a stored session, then loads everything.
  ///
  /// The token is passed in rather than read from storage here, so this class
  /// stays free of platform plugins and can be driven by tests.
  Future<void> bootstrap({
    String? savedToken,
    void Function(String token) onToken = _ignoreToken,
  }) async {
    _persistToken = onToken;
    _bootstrapping = true;
    _notify();
    try {
      if (savedToken == null || savedToken.isEmpty) {
        _signedIn = false;
        return;
      }
      _token = savedToken;
      backend.setToken(savedToken);
      _me = await backend.getMe();
      _signedIn = true;
      await _setUpEncryption();
      await _loadInitialData();
      _startRealtime();
    } catch (error) {
      if (isAuthFailure(error)) {
        // The stored token is stale: forget it rather than looping on a
        // session that cannot work.
        await _forgetSession();
      } else {
        _lastError = describeError(error);
      }
    } finally {
      _bootstrapping = false;
      _notify();
    }
  }

  Future<void> signIn(String username, String password) =>
      _authenticate(() => backend.login(username: username, password: password));

  Future<void> signUp(String username, String password, String displayName) =>
      _authenticate(() => backend.register(
            username: username,
            password: password,
            displayName: displayName,
          ));

  Future<void> _authenticate(Future<AuthResult> Function() call) async {
    _lastError = null;
    _notify();
    try {
      final result = await call();
      _token = result.token;
      backend.setToken(result.token);
      _me = result.user;
      _signedIn = true;
      _persistToken(result.token);
      await _setUpEncryption();
      await _loadInitialData();
      _startRealtime();
    } catch (error) {
      _lastError = describeError(error);
    } finally {
      _notify();
    }
  }

  Future<void> signOut() async {
    try {
      await backend.logout();
    } catch (_) {
      // Signing out must work with the server unreachable; the local session is
      // going away either way.
    }
    await _forgetSession();
    _notify();
  }

  /// Whether the account has a key backup, so the UI can offer restore instead of
  /// setup. False on any failure: an unreachable server must not read as "no
  /// backup", and the caller shows its own error in that case.
  Future<bool> hasKeyRecoveryBackup() async {
    try {
      return await crypto.recovery.hasBackup();
    } catch (error) {
      if (!isAuthFailure(error)) _lastError = describeError(error);
      _notify();
      return false;
    }
  }

  /// Seals this device's keys under [passphrase] and stores the backup.
  Future<bool> setUpKeyRecovery(String passphrase) async {
    try {
      await crypto.recovery.save(passphrase);
      return true;
    } catch (error) {
      if (!isAuthFailure(error)) _lastError = describeError(error);
      _notify();
      return false;
    }
  }

  /// Replaces this device's keys with the account's backup, then reloads so the
  /// newly readable history appears.
  ///
  /// Reloading rather than patching: every message on screen was decrypted with the
  /// old keys, and the honest way to show what the restored ones can read is to
  /// open the threads again.
  Future<bool> restoreKeyRecovery(String passphrase) async {
    final userId = _me?.id;
    if (userId == null) return false;
    try {
      await crypto.restoreFromRecovery(passphrase, userId: userId);
      _decryptedKeysChanged();
      await _loadInitialData();
      if (_openConversationId != null) await _loadHistory(_openConversationId!);
      _notify();
      return true;
    } catch (error) {
      if (!isAuthFailure(error)) _lastError = describeError(error);
      _notify();
      return false;
    }
  }

  /// Removes the account's backup. The keys on this device are untouched.
  Future<bool> removeKeyRecovery() async {
    try {
      await crypto.recovery.remove();
      return true;
    } catch (error) {
      if (!isAuthFailure(error)) _lastError = describeError(error);
      _notify();
      return false;
    }
  }

  /// Forgets decrypted bodies, because they were opened with keys this device no
  /// longer has.
  void _decryptedKeysChanged() {
    _localBodies.clear();
  }

  /// Deletes this account, then signs this device out.
  ///
  /// The sign-out is the point: the account is gone, so the token cannot work
  /// any more and the app must not pretend otherwise. Only after the server
  /// confirms does anything local change — a failure leaves the session intact so
  /// the user can try again rather than being stranded signed-out of a live
  /// account.
  Future<AccountDeletion?> deleteAccount({required String password}) async {
    try {
      final summary = await backend.deleteAccount(password: password);
      await signOut();
      return summary;
    } catch (error) {
      if (!isAuthFailure(error)) _lastError = describeError(error);
      _notify();
      return null;
    }
  }

  /// The token of the current session, for callers that build URLs by hand.
  String? get token => _token;

  Future<void> _forgetSession() async {
    _stopRealtime();
    _persistToken('');
    _token = null;
    backend.setToken(null);
    _me = null;
    _signedIn = false;
    _conversations.clear();
    _conversationOrder = const [];
    _messages.clear();
    _loadedConversations.clear();
    _hasOlder.clear();
    _typing.clear();
    _presence.clear();
    contacts = const [];
    invites = const [];
    _openConversationId = null;
  }

  /// Whether this manager has been disposed.
  ///
  /// Several things here start async work and report the result when it lands: a
  /// decryption, a key collection, a catch-up page, an attachment fetch. Any of
  /// those can finish *after* the manager is disposed — the app was closed, or a
  /// test moved on — and notifying a disposed ChangeNotifier throws. The work is
  /// not worth reporting by then, so every notification goes through [_notify].
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _stopRealtime();
    _typingExpiryTimer?.cancel();
    _typingRefreshTimer?.cancel();
    super.dispose();
  }

  /// Notifies listeners, unless this manager is already disposed.
  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }

  /// Brings up this install's encryption identity.
  ///
  /// A failure here is not fatal to the session: the app works, but messages
  /// are visibly unencrypted/unreadable and the UI says so, which is better
  /// than refusing to start.
  Future<void> _setUpEncryption() async {
    final me = _me;
    if (me == null) return;
    try {
      await crypto.initialize(
        userId: me.id,
        label: _deviceLabel(),
        platform: _platformName(),
      );
      if (crypto.reregistered) {
        // The server had no record of this device (a reset database, usually).
        // The keys are unchanged, so this is informational, not a warning: no
        // conversation needs re-verifying.
        _lastError = 'This device was registered with the server again; '
            'your encryption keys are unchanged.';
      }
    } catch (error) {
      _lastError = 'Encryption is not available on this device: ${describeError(error)}';
    }
  }

  static String _deviceLabel() => defaultTargetPlatform == TargetPlatform.linux
      ? 'Linux desktop'
      : defaultTargetPlatform == TargetPlatform.macOS
          ? 'macOS desktop'
          : defaultTargetPlatform == TargetPlatform.windows
              ? 'Windows desktop'
              : defaultTargetPlatform == TargetPlatform.android
                  ? 'Android device'
                  : defaultTargetPlatform == TargetPlatform.iOS
                      ? 'iOS device'
                      : 'This device';

  static String _platformName() => switch (defaultTargetPlatform) {
        TargetPlatform.android => 'android',
        TargetPlatform.iOS => 'ios',
        TargetPlatform.macOS => 'macos',
        TargetPlatform.windows => 'windows',
        TargetPlatform.linux => 'linux',
        TargetPlatform.fuchsia => 'fuchsia',
      };

  /// Whether this device can encrypt and decrypt.
  bool get encryptionReady => crypto.ready;

  /// Whether a conversation's outgoing messages can be sealed right now.
  bool canEncryptConversation(String conversationId) {
    final conversation = _conversations[conversationId];
    if (conversation == null) return false;
    return crypto.canEncrypt(conversation);
  }

  /// This device's key fingerprint, for the safety-number screen.
  String get ownFingerprint => crypto.ownFingerprint;

  Future<void> _loadInitialData() async {
    final results = await Future.wait([
      backend.listConversations(),
      backend.listContacts(),
      backend.listInvites(),
    ]);
    for (final conversation in results[0] as List<Conversation>) {
      _conversations[conversation.id] = conversation;
    }
    contacts = results[1] as List<Contact>;
    invites = results[2] as List<Invite>;
    _reorderConversations();
  }

  /// Reloads everything the lists show. Used after reconnecting, and by the
  /// pull-to-refresh gesture.
  Future<void> refresh() async {
    try {
      await _loadInitialData();
      final open = _openConversationId;
      if (open != null) {
        await _catchUp(open);
      }
    } catch (error) {
      if (isAuthFailure(error)) {
        await _forgetSession();
      } else {
        _lastError = describeError(error);
      }
    } finally {
      _notify();
    }
  }

  // --- conversations -----------------------------------------------------

  final Map<String, Conversation> _conversations = {};
  List<String> _conversationOrder = const [];

  /// Conversation ids: pinned first, then most recent activity.
  List<String> get conversationIds => _conversationOrder;

  Conversation? conversation(String id) => _conversations[id];

  void _reorderConversations() {
    final ids = _conversations.keys.toList()
      ..sort((a, b) {
        final left = _conversations[a]!;
        final right = _conversations[b]!;
        if (left.pinned != right.pinned) return left.pinned ? -1 : 1;
        final leftTime = _activityTime(left);
        final rightTime = _activityTime(right);
        return rightTime.compareTo(leftTime);
      });
    _conversationOrder = ids;
  }

  static DateTime _activityTime(Conversation conversation) {
    final updated = conversation.updatedAt.toDateTime();
    final created = conversation.createdAt.toDateTime();
    return updated.isAfter(created) ? updated : created;
  }

  Conversation? _upsertConversation(Conversation conversation) {
    _conversations[conversation.id] = conversation;
    _reorderConversations();
    return _conversations[conversation.id];
  }

  /// Forgets a conversation locally: used when leaving it or being removed.
  void _forgetConversationLocal(String conversationId) {
    _conversations.remove(conversationId);
    _messages.remove(conversationId);
    _loadedConversations.remove(conversationId);
    _hasOlder.remove(conversationId);
    _typing.remove(conversationId);
    if (_openConversationId == conversationId) _openConversationId = null;
    _reorderConversations();
    _notify();
  }

  // --- conversation actions ---------------------------------------------

  /// Opens (or reuses) the one-to-one conversation with somebody.
  Future<Conversation?> startDirectChat({String? username, String? userId}) async {
    try {
      final conversation = await backend.createDirectConversation(username: username, userId: userId);
      _upsertConversation(conversation);
      _notify();
      return conversation;
    } catch (error) {
      if (!isAuthFailure(error)) _lastError = describeError(error);
      _notify();
      return null;
    }
  }

  Future<Conversation?> startGroupChat(String title, List<String> usernames) async {
    try {
      final conversation = await backend.createGroupConversation(title: title, usernames: usernames);
      _upsertConversation(conversation);
      _notify();
      return conversation;
    } catch (error) {
      if (!isAuthFailure(error)) _lastError = describeError(error);
      _notify();
      return null;
    }
  }

  /// Mute or pin; both are the caller's own flags, not the conversation's.
  Future<void> setConversationFlags(String conversationId, {bool? muted, bool? pinned}) async {
    try {
      _upsertConversation(
        await backend.updateConversation(conversationId, muted: muted, pinned: pinned),
      );
      _notify();
    } catch (error) {
      if (!isAuthFailure(error)) _lastError = describeError(error);
      _notify();
    }
  }

  Future<void> renameConversation(String conversationId, String title) async {
    try {
      _upsertConversation(await backend.updateConversation(conversationId, title: title));
      _notify();
    } catch (error) {
      if (!isAuthFailure(error)) _lastError = describeError(error);
      _notify();
    }
  }

  Future<void> addMembers(String conversationId, List<String> usernames) async {
    try {
      _upsertConversation(await backend.addMembers(conversationId, usernames: usernames));
      _notify();
    } catch (error) {
      if (!isAuthFailure(error)) _lastError = describeError(error);
      _notify();
    }
  }

  /// Leaves a conversation (removes the caller from the member list).
  Future<void> leaveConversation(String conversationId) async {
    try {
      await backend.removeMember(conversationId);
      _forgetConversationLocal(conversationId);
    } catch (error) {
      if (!isAuthFailure(error)) _lastError = describeError(error);
      _notify();
    }
  }

  /// Removes somebody else from a group; the server allows this for owners.
  Future<void> removeMember(String conversationId, {required String userId}) async {
    try {
      _upsertConversation(await backend.removeMember(conversationId, userId: userId));
      _notify();
    } catch (error) {
      if (!isAuthFailure(error)) _lastError = describeError(error);
      _notify();
    }
  }

  /// The thread currently on screen. Read receipts and "mark read on arrival"
  /// key off this.
  String? _openConversationId;
  String? get openConversationId => _openConversationId;

  /// Opens a conversation: loads history if needed, marks it read, and from
  /// then on treats arriving messages as read on arrival.
  Future<void> openConversation(String conversationId) async {
    _openConversationId = conversationId;
    _notify();
    final conversation = _conversations[conversationId];
    if (conversation != null) {
      // Keys first: history that arrives before the sender keys is unreadable.
      await crypto.prepareConversation(conversation);
    }
    if (!_loadedConversations.contains(conversationId)) {
      await _loadHistory(conversationId);
    } else {
      await _decryptHistory(conversationId);
    }
    await markRead(conversationId);
  }

  void closeConversation(String conversationId) {
    if (_openConversationId != conversationId) return;
    _openConversationId = null;
    _stopTyping(conversationId);
    _notify();
  }

  // --- messages ----------------------------------------------------------

  final Map<String, List<ChatMessage>> _messages = {};
  final Map<String, bool> _hasOlder = {};
  final Map<String, bool> _loadingHistory = {};
  final Set<String> _loadedConversations = {};

  List<ChatMessage> messages(String conversationId) => _messages[conversationId] ?? const [];
  bool hasOlder(String conversationId) => _hasOlder[conversationId] ?? false;
  bool loadingHistory(String conversationId) => _loadingHistory[conversationId] ?? false;
  bool historyLoaded(String conversationId) => _loadedConversations.contains(conversationId);

  Future<void> _loadHistory(String conversationId, {int limit = 50}) async {
    _loadingHistory[conversationId] = true;
    _notify();
    try {
      final page = await backend.listMessages(conversationId, limit: limit);
      _messages[conversationId] = page.messages.map(ChatMessage.new).toList();
      _hasOlder[conversationId] = page.hasMore;
      _loadedConversations.add(conversationId);
      await _decryptHistory(conversationId);
    } catch (error) {
      if (isAuthFailure(error)) {
        await _forgetSession();
      } else {
        _lastError = describeError(error);
      }
    } finally {
      _loadingHistory[conversationId] = false;
      _notify();
    }
  }

  /// Loads the page above the oldest message we hold (scrolling up).
  Future<void> loadOlder(String conversationId) async {
    final existing = _messages[conversationId];
    if (existing == null || existing.isEmpty) return;
    if (loadingHistory(conversationId) || !hasOlder(conversationId)) return;
    _loadingHistory[conversationId] = true;
    _notify();
    try {
      final oldest = existing.firstWhere((m) => !m.isPending, orElse: () => existing.first);
      if (oldest.seq == 0) return;
      final page = await backend.listMessages(conversationId, beforeSeq: oldest.seq, limit: 50);
      _messages[conversationId] = _dedupe([
        ...page.messages.map(ChatMessage.new),
        ...existing,
      ]);
      _hasOlder[conversationId] = page.hasMore;
      await _decryptHistory(conversationId);
    } catch (error) {
      if (!isAuthFailure(error)) _lastError = describeError(error);
    } finally {
      _loadingHistory[conversationId] = false;
      _notify();
    }
  }

  /// Pulls everything appended since the newest message we hold. This is the
  /// reconnect path: rather than guessing what was missed, ask the server.
  Future<void> _catchUp(String conversationId) async {
    final existing = _messages[conversationId];
    if (existing == null || existing.isEmpty) {
      await _loadHistory(conversationId);
      return;
    }
    final newest = existing.where((m) => !m.isPending);
    if (newest.isEmpty) return;
    final lastSeq = newest.map((m) => m.seq).reduce(math.max);
    if (lastSeq == 0) return;
    try {
      final page = await backend.listMessages(conversationId, afterSeq: lastSeq, limit: 200);
      if (page.messages.isEmpty) return;
      _messages[conversationId] = _dedupe([...existing, ...page.messages.map(ChatMessage.new)]);
      // Everything merged here is sealed too, and this is the one merge path
      // that used to skip decryption: a message pulled in by a catch-up sat at
      // "Opening…" for good, because nothing else ever looked at it.
      await _decryptHistory(conversationId);
    } catch (error) {
      if (!isAuthFailure(error)) _lastError = describeError(error);
    }
  }

  /// Sorts by seq and drops duplicates, keeping pending sends at the end where
  /// they belong until the server gives them a position.
  static List<ChatMessage> _dedupe(List<ChatMessage> messages) {
    final byId = <String, ChatMessage>{};
    for (final message in messages) {
      if (message.id.isEmpty) continue;
      byId[message.id] = message;
    }
    return byId.values.toList()
      ..sort((a, b) {
        if (a.seq == 0 && b.seq == 0) return a.id.compareTo(b.id);
        if (a.seq == 0) return 1;
        if (b.seq == 0) return -1;
        return a.seq.compareTo(b.seq);
      });
  }

  /// Opens every sealed message in a loaded thread.
  ///
  /// Unreadable ones stay uncached, so the next attempt (after a sender key
  /// arrives) can succeed. A message whose key is still missing is reported once
  /// per pass, not per rebuild.
  Future<void> _decryptHistory(String conversationId, {bool retried = false}) async {
    final conversation = _conversations[conversationId];
    final list = _messages[conversationId];
    if (conversation == null || list == null || !crypto.ready) return;

    final pending = <ChatMessage>[];
    for (final entry in list) {
      if (!entry.message.encrypted || entry.message.deleted) continue;
      if (crypto.cached(entry.message) != null || _localBodies.containsKey(entry.id)) continue;
      pending.add(entry);
    }
    if (pending.isEmpty) return;

    _decrypting.addAll(pending.map((e) => e.id));
    _notify();

    var missing = 0;
    for (final entry in pending) {
      final body = await crypto.decryptMessage(
        conversation: conversation,
        message: entry.message,
        ownMessage: entry.message.senderId == _me?.id,
      );
      _decrypting.remove(entry.id);
      if (body.ok) {
        _cacheLocalBody(entry.id, body);
        _undecryptable.remove(entry.id);
      } else {
        // Remembered so the bubble can explain itself rather than spinning.
        _undecryptable[entry.id] = body.unreadable ?? 'This message cannot be read';
        missing++;
      }
    }

    if (missing > 0 && !retried) {
      // A key may have been deposited since we last looked: ask once, then try
      // the whole thread again. Only once, so a permanently unreadable message
      // cannot loop.
      final learned = await crypto.collectKeys(conversation);
      if (learned > 0) {
        await _decryptHistory(conversationId, retried: true);
        return;
      }
    }
    _notify();
  }

  /// The body the UI renders for a message: decrypted text, or a reason it
  /// cannot be shown.
  DecryptedMessage bodyOf(ChatMessage entry) {
    final local = _localBodies[entry.id];
    if (local != null) return local;
    if (entry.message.deleted) {
      return const DecryptedMessage(text: '');
    }
    final cached = crypto.cached(entry.message);
    if (cached != null) return cached;
    if (entry.message.encrypted) {
      // Three states worth telling apart: still being opened, tried and failed
      // (with the reason), and not reached yet (a decryption is queued).
      if (!crypto.ready) {
        // Nothing can be opened at all, which is worth saying plainly rather
        // than leaving every bubble on a placeholder for ever.
        return const DecryptedMessage(
          text: '',
          unreadable: 'Encryption is not set up on this device',
        );
      }
      final failure = _undecryptable[entry.id];
      if (failure != null) {
        return DecryptedMessage(text: '', unreadable: failure);
      }
      return DecryptedMessage(
        text: '',
        unreadable: _decrypting.contains(entry.id) ? 'Opening…' : 'Encrypted',
      );
    }
    return DecryptedMessage(
      text: entry.message.text,
      replyToId: entry.message.replyToId.isEmpty ? null : entry.message.replyToId,
      replyToText: entry.message.hasReplyTo() ? entry.message.replyTo.text : null,
      attachments: entry.message.attachments
          .map((a) => DecryptedAttachment(
                blobId: a.id,
                filename: a.filename,
                contentType: a.contentType,
                size: a.size.toInt(),
                fileKey: Uint8List(0),
                nonce: Uint8List(0),
              ))
          .toList(),
    );
  }

  /// Merges one stored message into a loaded thread. A conversation that was
  /// never opened is left alone: its history is fetched when it is.
  void _mergeMessage(String conversationId, Message message) {
    final list = _messages[conversationId];
    if (list == null) return;
    final index = list.indexWhere((m) => m.id == message.id);
    if (index >= 0) {
      list[index] = ChatMessage(message);
    } else {
      list.add(ChatMessage(message));
    }
    _messages[conversationId] = _dedupe(list);
  }

  // --- sending -----------------------------------------------------------

  /// Sends a message, showing it immediately.
  ///
  /// The body is sealed here, before anything leaves the device: the optimistic
  /// copy the UI shows carries the plaintext only in memory, and the record that
  /// replaces it holds the ciphertext the server stored.
  ///
  /// The optimistic copy also carries a `clientMessageId`; the stored message
  /// replaces it when the server answers. A failure keeps the bubble on screen
  /// with a retry affordance rather than losing what the user typed.
  Future<void> sendMessage(
    String conversationId, {
    required String text,
    List<Attachment> attachments = const [],
    String? replyToId,
    MessageContent? sealedBody,
  }) async {
    final conversation = _conversations[conversationId];
    final clientMessageId = _newClientMessageId();

    // What the reader will see, once opened on their device.
    final body = sealedBody ??
        MessageContent(
          text: text,
          attachments: attachments
              .map((a) => EncryptedAttachment(
                    blobId: a.id,
                    fileKey: Uint8List(0),
                    nonce: Uint8List(0),
                    filename: a.filename,
                    contentType: a.contentType,
                    size: a.size.toInt(),
                  ))
              .toList(),
        );

    // The wire copy: sealed bytes only. Locally the UI keeps the plaintext in
    // the decryption cache, so it does not have to be sent to itself to be read.
    // Encryption is the default and the only path: a conversation whose peer
    // cannot receive a sealed message is refused above rather than downgraded,
    // because a silent downgrade is the one failure a user would never notice.
    Message? sealedRecord;
    if (conversation != null && crypto.ready) {
      try {
        final seal = await crypto.sealMessage(conversation: conversation, content: body);
        sealedRecord = Message(
          id: 'pending-$clientMessageId',
          conversationId: conversationId,
          senderId: _me?.id ?? '',
          ciphertext: seal.ciphertext,
          nonce: seal.nonce,
          senderDeviceKeyId: seal.deviceKeyId,
          keyEpoch: seal.epoch,
          cryptoVersion: cryptoVersion,
          encrypted: true,
          attachments: attachments,
          clientMessageId: clientMessageId,
          createdAt: Timestamp.fromDateTime(DateTime.now().toUtc()),
          kind: MessageKind.MESSAGE_KIND_TEXT,
        );
      } catch (error) {
        _lastError = error is CryptoFailure ? error.message : describeError(error);
        _notify();
        return;
      }
    }

    final draft = sealedRecord ??
        Message(
          id: 'pending-$clientMessageId',
          conversationId: conversationId,
          senderId: _me?.id ?? '',
          text: text,
          attachments: attachments,
          replyToId: replyToId ?? '',
          clientMessageId: clientMessageId,
          createdAt: Timestamp.fromDateTime(DateTime.now().toUtc()),
          kind: MessageKind.MESSAGE_KIND_TEXT,
        );

    // Cache the plaintext under the pending id so the bubble renders at once,
    // and again under the stored id when the server answers.
    _cacheLocalBody(draft.id, DecryptedMessage(
      text: body.text,
      attachments: body.attachments
          .map((a) => DecryptedAttachment(
                blobId: a.blobId,
                filename: a.filename,
                contentType: a.contentType,
                size: a.size,
                fileKey: a.fileKey,
                nonce: a.nonce,
              ))
          .toList(),
      replyToId: replyToId,
      replyToText: _replyPreviewText(conversationId, replyToId),
    ));

    final list = _messages.putIfAbsent(conversationId, () => []);
    list.add(ChatMessage(draft, state: SendState.sending));
    // Move the row to the top of the list before the round trip finishes.
    final current = _conversations[conversationId];
    if (current != null) {
      _upsertConversation(current.deepCopy()..lastMessage = draft);
    }
    _notify();

    await _deliver(conversationId, draft);
  }

  /// Sends a message with files: each file is sealed, uploaded as ciphertext,
  /// and described inside the message envelope so only the reader can see what
  /// it is.
  ///
  /// This is the path the composer uses. Keeping it here rather than in the
  /// widget means the UI never touches key material.
  Future<void> sendMessageWithFiles(
    String conversationId, {
    required String text,
    List<AttachmentUpload> files = const [],
    String? replyToId,
  }) async {
    final conversation = _conversations[conversationId];
    if (conversation == null) return;

    // Never send attachment bytes in the clear, even before crypto bootstrap.
    if (files.isNotEmpty && !crypto.ready) {
      _lastError = 'Cannot attach files until encryption is ready.';
      _notify();
      return;
    }
    final sealedAttachments = <EncryptedAttachment>[];
    for (final file in files) {
      try {
        final sealed = await crypto.sealFile(file.bytes);
        final uploaded = await backend.uploadAttachment(
          filename: file.filename,
          contentType: file.contentType,
          data: sealed.ciphertext,
          encrypted: true,
        );
        sealedAttachments.add(EncryptedAttachment(
          blobId: uploaded.id,
          fileKey: sealed.key,
          nonce: sealed.nonce,
          filename: file.filename,
          contentType: file.contentType,
          size: file.bytes.length,
        ));
      } catch (error) {
        _lastError = 'Could not attach ${file.filename}: ${describeError(error)}';
        _notify();
        return;
      }
    }

    final body = MessageContent(
      text: text,
      attachments: sealedAttachments,
      replyTo: _replyQuoteFor(conversationId, replyToId),
    );
    await sendMessage(
      conversationId,
      text: text,
      replyToId: replyToId,
      sealedBody: crypto.ready ? body : null,
    );
  }

  ReplyQuote? _replyQuoteFor(String conversationId, String? replyToId) {
    if (replyToId == null) return null;
    for (final entry in messages(conversationId)) {
      if (entry.id == replyToId) {
        return ReplyQuote(messageId: replyToId, text: bodyOf(entry).text);
      }
    }
    return ReplyQuote(messageId: replyToId, text: '');
  }

  /// Re-reads the device keys of a conversation, for tests and for the case
  /// where a peer publishes a key after the conversation was opened.
  Future<void> refreshConversationKeys(String conversationId) async {
    final conversation = _conversations[conversationId];
    if (conversation == null) return;
    await crypto.prepareConversation(conversation);
    _notify();
  }

  /// Re-sends a message that failed.
  Future<void> retry(String conversationId, String pendingMessageId) async {
    final list = _messages[conversationId];
    if (list == null) return;
    final index = list.indexWhere((m) => m.id == pendingMessageId);
    if (index < 0) return;
    final failed = list[index];
    if (!failed.isPending) return;
    list[index] = failed.copyWith(state: SendState.sending, error: null);
    _notify();
    // The sealed bytes are re-sent unchanged, so the server's idempotency key
    // still matches if the first attempt actually landed.
    await _deliver(conversationId, failed.message);
  }

  Future<void> _deliver(String conversationId, Message draft) async {
    try {
      final Message stored;
      if (draft.encrypted) {
        stored = await backend.sendEncryptedMessage(
          conversationId,
          ciphertext: Uint8List.fromList(draft.ciphertext),
          nonce: Uint8List.fromList(draft.nonce),
          senderDeviceKeyId: draft.senderDeviceKeyId,
          keyEpoch: draft.keyEpoch,
          cryptoVersion: draft.cryptoVersion,
          attachmentIds: draft.attachments.map((a) => a.id).toList(),
          clientMessageId: draft.clientMessageId,
        );
      } else {
        stored = await backend.sendMessage(
          conversationId,
          text: draft.text,
          attachmentIds: draft.attachments.map((a) => a.id).toList(),
          replyToId: draft.replyToId.isEmpty ? null : draft.replyToId,
          clientMessageId: draft.clientMessageId,
        );
      }
      // The plaintext was cached under the pending id; carry it over so the
      // bubble does not flicker into "opening" the moment the server answers.
      _adoptLocalBody(draft.id, stored.id);
      _replacePending(conversationId, draft, stored);
    } catch (error) {
      if (isAuthFailure(error)) _lastError = describeError(error);
      _markFailed(conversationId, draft, describeError(error));
    }
  }

  /// Caches a decrypted body locally, keyed by message id.
  void _cacheLocalBody(String messageId, DecryptedMessage body) => _localBodies[messageId] = body;

  void _adoptLocalBody(String fromId, String toId) {
    final body = _localBodies.remove(fromId);
    if (body != null) _localBodies[toId] = body;
  }

  String? _replyPreviewText(String conversationId, String? replyToId) {
    if (replyToId == null) return null;
    for (final entry in messages(conversationId)) {
      if (entry.id == replyToId) return bodyOf(entry).text;
    }
    return null;
  }

  /// Plaintext bodies for messages this device sealed or opened.
  final Map<String, DecryptedMessage> _localBodies = {};

  /// Messages whose decryption is in flight right now, and messages that were
  /// tried and could not be opened (with the reason).
  ///
  /// Without these, a bubble whose decryption has not been *attempted* and one
  /// whose decryption *failed* look identical — both render as a placeholder —
  /// and a message that simply never got an attempt (the catch-up path used to
  /// skip them) sits there saying "Opening…" forever.
  final Set<String> _decrypting = {};
  final Map<String, String> _undecryptable = {};

  void _replacePending(String conversationId, Message draft, Message stored) {
    final list = _messages[conversationId];
    if (list == null) return;

    // Drop every optimistic copy of this send, then the authoritative one, then
    // add it back.
    //
    // Matching on `clientMessageId` alone is not enough to find *the pending*
    // one: the server echoes a stored message back to its sender, so by the time
    // the send response arrives the list can already hold the stored copy — with
    // the same clientMessageId — and a single indexWhere would match that first
    // and "replace" it with itself, leaving the optimistic entry behind as a
    // bubble nothing can ever decrypt. Removing by identity avoids the ordering
    // question entirely.
    list.removeWhere((m) =>
        m.id == draft.id ||
        (m.isPending &&
            draft.clientMessageId.isNotEmpty &&
            m.message.clientMessageId == draft.clientMessageId));
    list.removeWhere((m) => m.id == stored.id);
    list.add(ChatMessage(stored));
    _messages[conversationId] = _dedupe(list);
    final conversation = _conversations[conversationId];
    if (conversation != null) {
      _upsertConversation(conversation.deepCopy()..lastMessage = stored);
    }
    _notify();
  }

  void _markFailed(String conversationId, Message draft, String error) {
    final list = _messages[conversationId];
    if (list == null) return;
    final index = list.indexWhere((m) => m.id == draft.id);
    if (index >= 0) {
      list[index] = ChatMessage(draft, state: SendState.failed, error: error);
    }
    _notify();
  }

  Future<void> editMessage(String conversationId, String messageId, String text) async {
    final conversation = _conversations[conversationId];
    try {
      Message stored;
      if (conversation != null && crypto.ready) {
        // The new text is sealed too: an edit must not be the one message the
        // server can read.
        final existing = _localBodies[messageId];
        final body = MessageContent(
          text: text,
          attachments: existing?.attachments
                  .map((a) => EncryptedAttachment(
                        blobId: a.blobId,
                        fileKey: a.fileKey,
                        nonce: a.nonce,
                        filename: a.filename,
                        contentType: a.contentType,
                        size: a.size,
                      ))
                  .toList() ??
              const [],
          replyTo: existing?.replyToId != null
              ? ReplyQuote(messageId: existing!.replyToId!, text: existing.replyToText ?? '')
              : null,
        );
        final seal = await crypto.sealMessage(conversation: conversation, content: body);
        stored = await backend.editEncryptedMessage(
          messageId,
          ciphertext: seal.ciphertext,
          nonce: seal.nonce,
          cryptoVersion: cryptoVersion,
        );
        _cacheLocalBody(messageId, DecryptedMessage(
          text: text,
          attachments: existing?.attachments ?? const [],
          replyToId: existing?.replyToId,
          replyToText: existing?.replyToText,
        ));
        _mergeMessage(conversationId, stored);
      } else {
        _mergeMessage(conversationId, await backend.editMessage(messageId, text));
      }
      _notify();
    } catch (error) {
      if (!isAuthFailure(error)) _lastError = describeError(error);
      _notify();
    }
  }

  Future<void> deleteMessage(String conversationId, String messageId) async {
    try {
      _mergeMessage(conversationId, await backend.deleteMessage(messageId));
      _notify();
    } catch (error) {
      if (!isAuthFailure(error)) _lastError = describeError(error);
      _notify();
    }
  }

  /// Adds the reaction if the user has not picked it yet, removes it if they
  /// have — one tap, one meaning.
  Future<void> toggleReaction(String conversationId, Message message, String emoji) async {
    final mine = message.reactions
        .where((reaction) => reaction.emoji == emoji)
        .any((reaction) => reaction.userIds.contains(_me?.id));
    debugPrint('[reaction] toggling $emoji on ${message.id} '
        'conv=$conversationId mine=$mine');
    try {
      final stored = mine
          ? await backend.removeReaction(message.id, emoji)
          : await backend.addReaction(message.id, emoji);
      // What the server returned, which is what the chip is drawn from: a
      // response without the reaction is the failure the UI cannot see.
      debugPrint('[reaction] server returned ${stored.reactions.length} '
          'reaction(s) on ${stored.id}');
      _mergeMessage(conversationId, stored);
      _notify();
    } catch (error) {
      debugPrint('[reaction] FAILED: $error');
      if (!isAuthFailure(error)) _lastError = describeError(error);
      _notify();
    }
  }

  /// Advances the read cursor and clears the unread badge.
  Future<int> markRead(String conversationId) async {
    try {
      final seq = await backend.markRead(conversationId);
      final conversation = _conversations[conversationId];
      if (conversation != null && conversation.unreadCount != 0) {
        _upsertConversation(conversation.deepCopy()..unreadCount = 0);
        _notify();
      }
      return seq;
    } catch (error) {
      if (!isAuthFailure(error)) _lastError = describeError(error);
      return 0;
    }
  }

  // --- typing ------------------------------------------------------------

  final Map<String, List<TypingIndicator>> _typing = {};

  /// Who is typing in a conversation right now, the caller excluded.
  List<TypingIndicator> typingIn(String conversationId) {
    final now = _clock();
    return (_typing[conversationId] ?? const <TypingIndicator>[])
        .where((t) => !t.expiredAt(now))
        .toList();
  }

  final Map<String, DateTime> _lastTypingSentAt = {};
  Timer? _typingRefreshTimer;
  Timer? _typingExpiryTimer;

  void _markTyping(String conversationId, String userId, String displayName) {
    if (userId.isEmpty || userId == _me?.id) return;
    final list = _typing.putIfAbsent(conversationId, () => []);
    final entry = TypingIndicator(userId, displayName, _clock().add(typingLifetime));
    final index = list.indexWhere((t) => t.userId == userId);
    if (index >= 0) {
      list[index] = entry;
    } else {
      list.add(entry);
    }
    _startTypingSweep();
    _notify();
  }

  void _clearTyping(String conversationId, String userId) {
    final list = _typing[conversationId];
    if (list == null) return;
    final before = list.length;
    list.removeWhere((t) => t.userId == userId);
    if (list.length != before) _notify();
  }

  /// A sweep so an indicator disappears even if its stop event never arrives.
  /// The timer only runs while somebody is typing.
  void _startTypingSweep() {
    if (_typingExpiryTimer?.isActive ?? false) return;
    _typingExpiryTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      var anyoneLeft = false;
      final now = _clock();
      for (final list in _typing.values) {
        final before = list.length;
        list.removeWhere((t) => t.expiredAt(now));
        if (list.isNotEmpty) anyoneLeft = true;
        if (list.length != before) _notify();
      }
      if (!anyoneLeft) {
        timer.cancel();
        _typingExpiryTimer = null;
      }
    });
  }

  /// Announces that the user is typing, at most once every [typingRefresh], and
  /// arranges the matching stop.
  void notifyTyping(String conversationId) {
    final now = _clock();
    final lastSent = _lastTypingSentAt[conversationId];
    if (lastSent == null || now.difference(lastSent) > typingRefresh) {
      _lastTypingSentAt[conversationId] = now;
      unawaited(backend.setTyping(conversationId, true).catchError((Object _) {}));
    }
    _typingRefreshTimer?.cancel();
    _typingRefreshTimer = Timer(const Duration(seconds: 2), () => _stopTyping(conversationId));
  }

  void stopTyping(String conversationId) => _stopTyping(conversationId);

  void _stopTyping(String conversationId) {
    _typingRefreshTimer?.cancel();
    _typingRefreshTimer = null;
    if (_lastTypingSentAt.remove(conversationId) == null) return;
    unawaited(backend.setTyping(conversationId, false).catchError((Object _) {}));
  }

  // --- realtime ----------------------------------------------------------

  StreamSubscription<Event>? _subscription;
  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;
  bool _realtimeConnected = false;

  bool get realtimeConnected => _realtimeConnected;

  void _startRealtime() {
    _subscription?.cancel();
    // The badge is cleared as soon as the stream is open.
    //
    // A healthy stream may deliver nothing for hours, so waiting for the first
    // event to clear a "Reconnecting…" badge leaves it showing for the whole
    // session — a status light reporting the opposite of the truth. `subscribe`
    // has put the request on the wire by the time it returns.
    _subscription = backend.subscribe().listen(
      _onEvent,
      onError: (Object _) {
        _realtimeConnected = false;
        _notify();
        _scheduleReconnect();
      },
      onDone: () {
        _realtimeConnected = false;
        _notify();
        _scheduleReconnect();
      },
      cancelOnError: true,
    );
    _realtimeConnected = true;
    _notify();
  }

  void _stopRealtime() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _subscription?.cancel();
    _subscription = null;
    _realtimeConnected = false;
    _reconnectAttempt = 0;
  }

  void _scheduleReconnect() {
    if (!_signedIn || _reconnectTimer != null) return;
    final delay = Duration(seconds: math.min(30, 1 << math.min(_reconnectAttempt, 5)));
    _reconnectAttempt++;
    _reconnectTimer = Timer(delay, () async {
      _reconnectTimer = null;
      if (!_signedIn) return;
      _reconnectAttempt = 0;
      await refresh();
      _startRealtime();
    });
  }

  void _onEvent(Event event) {
    if (!_realtimeConnected) {
      _realtimeConnected = true;
      _reconnectAttempt = 0;
    }
    switch (event.whichPayload()) {
      case Event_Payload.hello:
        break;
      case Event_Payload.message:
        _onMessageEvent(event.message.message);
      case Event_Payload.typing:
        final typing = event.typing;
        if (typing.typing) {
          _markTyping(typing.conversationId, typing.userId, typing.displayName);
        } else {
          _clearTyping(typing.conversationId, typing.userId);
        }
      case Event_Payload.read:
        _onReadEvent(event.read);
      case Event_Payload.conversation:
        _onConversationEvent(event.conversation);
      case Event_Payload.presence:
        _presence[event.presence.userId] = event.presence.presence;
        _notify();
      case Event_Payload.contact:
        unawaited(_reloadContacts());
      case Event_Payload.notSet:
        break;
    }
  }

  void _onMessageEvent(Message message) {
    _mergeMessage(message.conversationId, message);
    if (message.encrypted && !message.deleted) {
      unawaited(_decryptArrival(message));
    }
    final conversation = _conversations[message.conversationId];
    if (conversation != null) {
      _upsertConversation(conversation.deepCopy()..lastMessage = message);
    }
    // A message from someone else in the open thread counts as read at once,
    // the way a messenger behaves when the window is in front of you.
    if (_openConversationId == message.conversationId && message.senderId != _me?.id) {
      unawaited(markRead(message.conversationId));
    }
    _notify();
  }

  /// Opens a message that just arrived, then repaints.
  Future<void> _decryptArrival(Message message) async {
    final conversation = _conversations[message.conversationId];
    if (conversation == null || !crypto.ready) return;
    var body = await crypto.decryptMessage(
      conversation: conversation,
      message: message,
      ownMessage: message.senderId == _me?.id,
    );
    if (!body.ok) {
      // The sender key may be waiting for us; fetch it and try again.
      final learned = await crypto.collectKeys(conversation);
      if (learned > 0) {
        body = await crypto.decryptMessage(
          conversation: conversation,
          message: message,
          ownMessage: message.senderId == _me?.id,
        );
      }
    }
    if (body.ok) _cacheLocalBody(message.id, body);
    _notify();
  }

  void _onReadEvent(ReadEvent event) {
    final conversation = _conversations[event.conversationId];
    if (conversation == null) return;
    final updated = conversation.deepCopy();
    for (final member in updated.members) {
      if (member.user.id == event.userId) {
        member.lastReadSeq = event.lastReadSeq;
      }
    }
    _upsertConversation(updated);
    _notify();
  }

  void _onConversationEvent(ConversationEvent event) {
    if (event.removed) {
      _conversations.remove(event.conversation.id);
      _reorderConversations();
    } else {
      _upsertConversation(event.conversation);
    }
    _notify();
  }

  Future<void> _reloadContacts() async {
    try {
      contacts = await backend.listContacts();
      _notify();
    } catch (_) {
      // A failed contact refresh is not worth interrupting the user over.
    }
  }

  // --- presence ----------------------------------------------------------

  final Map<String, Presence> _presence = {};

  Presence presenceOf(String userId) {
    if (userId == _me?.id) return Presence.PRESENCE_ONLINE;
    return _presence[userId] ?? Presence.PRESENCE_OFFLINE;
  }

  // --- contacts and invites ---------------------------------------------

  List<Contact> contacts = const [];
  List<Invite> invites = const [];

  Future<List<User>> searchUsers(String query) async {
    try {
      return await backend.searchUsers(query);
    } catch (error) {
      if (!isAuthFailure(error)) _lastError = describeError(error);
      _notify();
      return const [];
    }
  }

  /// Becomes contacts with a handle, returning the conversation it opened.
  Future<Conversation?> addContact(String username) async {
    try {
      final result = await backend.addContact(username);
      await _reloadContacts();
      final conversation = result.conversation;
      if (conversation != null) _upsertConversation(conversation);
      _notify();
      return conversation ?? (await _findDirectWith(result.contact.user.id));
    } catch (error) {
      if (!isAuthFailure(error)) _lastError = describeError(error);
      _notify();
      return null;
    }
  }

  Future<Conversation?> _findDirectWith(String userId) async {
    try {
      final conversation = await backend.createDirectConversation(userId: userId);
      _upsertConversation(conversation);
      _notify();
      return conversation;
    } catch (_) {
      return null;
    }
  }

  Future<void> removeContact(String userId) async {
    try {
      await backend.removeContact(userId);
      await _reloadContacts();
    } catch (error) {
      if (!isAuthFailure(error)) _lastError = describeError(error);
      _notify();
    }
  }

  Future<Invite?> createInvite({int expiresInHours = 0, int maxUses = 0}) async {
    try {
      final invite = await backend.createInvite(expiresInHours: expiresInHours, maxUses: maxUses);
      invites = [invite, ...invites];
      _notify();
      return invite;
    } catch (error) {
      if (!isAuthFailure(error)) _lastError = describeError(error);
      _notify();
      return null;
    }
  }

  Future<void> revokeInvite(String code) async {
    try {
      await backend.revokeInvite(code);
      invites = await backend.listInvites();
      _notify();
    } catch (error) {
      if (!isAuthFailure(error)) _lastError = describeError(error);
      _notify();
    }
  }

  Future<InvitePreview?> previewInvite(String code) async {
    try {
      return await backend.previewInvite(code);
    } catch (error) {
      _lastError = describeError(error);
      _notify();
      return null;
    }
  }

  Future<RedeemResult?> redeemInvite(String code) async {
    try {
      final result = await backend.redeemInvite(code);
      await _reloadContacts();
      _upsertConversation(result.conversation);
      _notify();
      return result;
    } catch (error) {
      _lastError = describeError(error);
      _notify();
      return null;
    }
  }

  // --- profile -----------------------------------------------------------

  Future<void> updateProfile({
    String? displayName,
    String? bio,
    String? avatarAttachmentId,
    String? accentColor,
    bool clearAvatar = false,
  }) async {
    try {
      _me = await backend.updateProfile(
        displayName: displayName,
        bio: bio,
        avatarAttachmentId: avatarAttachmentId,
        accentColor: accentColor,
        clearAvatar: clearAvatar,
      );
      _notify();
    } catch (error) {
      if (!isAuthFailure(error)) _lastError = describeError(error);
      _notify();
    }
  }

  // --- presentation helpers ---------------------------------------------

  /// A URL the UI can hand to an image widget.
  String fileUrl(String path) => backend.fileUrl(path);

  /// Preview from locally opened content, never plaintext copied to the server.
  DecryptedMessage? previewBody(Message message) =>
      _localBodies[message.id] ?? crypto.cached(message);

  /// Whether the user has confirmed the safety number of a conversation.
  ///
  /// The verdict is local and per conversation: it records that a human
  /// compared the numbers, not that the server said so.
  final Set<String> _verified = {};

  bool isVerified(String conversationId) => _verified.contains(conversationId);

  void setVerified(String conversationId, bool verified) {
    if (verified) {
      _verified.add(conversationId);
    } else {
      _verified.remove(conversationId);
    }
    _saveVerification();
    _notify();
  }

  /// Persisted through the same store as the token, so a verification survives
  /// a restart: re-verifying on every launch is how people stop verifying.
  void _saveVerification() => _persistVerification?.call(_verified.toList());

  void Function(List<String> verified)? _persistVerification;

  /// Seeds the verified list from storage at startup.
  void restoreVerification(List<String> verified) {
    _verified
      ..clear()
      ..addAll(verified);
  }

  /// Installs the storage hook, called once during bootstrap.
  void hookVerificationStorage(void Function(List<String> verified) save) {
    _persistVerification = save;
  }

  /// The other participant of a direct conversation, if there is one.
  User? peerOf(Conversation conversation) =>
      conversation.hasPeer() ? conversation.peer : null;

  /// The name a conversation list row shows.
  String titleOf(Conversation conversation) {
    if (conversation.title.isNotEmpty) return conversation.title;
    final peer = peerOf(conversation);
    if (peer != null && peer.displayName.isNotEmpty) return peer.displayName;
    return 'Conversation';
  }

  /// A group's members except the caller, for "Ada, Grace and 3 others".
  List<User> otherMembers(Conversation conversation) => conversation.members
      .where((member) => member.user.id != _me?.id)
      .map((member) => member.user)
      .toList();

  /// The peer's read cursor: how far the other side has read, which is what a
  /// "Seen" marker compares against.
  int peerReadSeq(Conversation conversation) {
    var highest = 0;
    for (final member in conversation.members) {
      if (member.user.id == _me?.id) continue;
      if (member.lastReadSeq.toInt() > highest) highest = member.lastReadSeq.toInt();
    }
    return highest;
  }

  static int _clientMessageCounter = 0;

  /// Locally unique send id. The server deduplicates retries by it, so it has
  /// to survive a reconnect; it need not be globally unique.
  static String _newClientMessageId() {
    _clientMessageCounter++;
    return '${DateTime.now().microsecondsSinceEpoch}-$_clientMessageCounter';
  }
}
