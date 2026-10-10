import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart';

import '../api/backend.dart';
import '../gen/ratatosk/v1/chat.pb.dart';
import '../gen/ratatosk/v1/common.pb.dart';
import '../gen/ratatosk/v1/social.pb.dart';

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
  AppState({required this.backend, DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final ChatBackend backend;

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
    notifyListeners();
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
    notifyListeners();
    try {
      if (savedToken == null || savedToken.isEmpty) {
        _signedIn = false;
        return;
      }
      _token = savedToken;
      backend.setToken(savedToken);
      _me = await backend.getMe();
      _signedIn = true;
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
      notifyListeners();
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
    notifyListeners();
    try {
      final result = await call();
      _token = result.token;
      backend.setToken(result.token);
      _me = result.user;
      _signedIn = true;
      _persistToken(result.token);
      await _loadInitialData();
      _startRealtime();
    } catch (error) {
      _lastError = describeError(error);
    } finally {
      notifyListeners();
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
    notifyListeners();
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

  @override
  void dispose() {
    _stopRealtime();
    _typingExpiryTimer?.cancel();
    _typingRefreshTimer?.cancel();
    super.dispose();
  }

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
      notifyListeners();
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
    notifyListeners();
  }

  // --- conversation actions ---------------------------------------------

  /// Opens (or reuses) the one-to-one conversation with somebody.
  Future<Conversation?> startDirectChat({String? username, String? userId}) async {
    try {
      final conversation = await backend.createDirectConversation(username: username, userId: userId);
      _upsertConversation(conversation);
      notifyListeners();
      return conversation;
    } catch (error) {
      if (!isAuthFailure(error)) _lastError = describeError(error);
      notifyListeners();
      return null;
    }
  }

  Future<Conversation?> startGroupChat(String title, List<String> usernames) async {
    try {
      final conversation = await backend.createGroupConversation(title: title, usernames: usernames);
      _upsertConversation(conversation);
      notifyListeners();
      return conversation;
    } catch (error) {
      if (!isAuthFailure(error)) _lastError = describeError(error);
      notifyListeners();
      return null;
    }
  }

  /// Mute or pin; both are the caller's own flags, not the conversation's.
  Future<void> setConversationFlags(String conversationId, {bool? muted, bool? pinned}) async {
    try {
      _upsertConversation(
        await backend.updateConversation(conversationId, muted: muted, pinned: pinned),
      );
      notifyListeners();
    } catch (error) {
      if (!isAuthFailure(error)) _lastError = describeError(error);
      notifyListeners();
    }
  }

  Future<void> renameConversation(String conversationId, String title) async {
    try {
      _upsertConversation(await backend.updateConversation(conversationId, title: title));
      notifyListeners();
    } catch (error) {
      if (!isAuthFailure(error)) _lastError = describeError(error);
      notifyListeners();
    }
  }

  Future<void> addMembers(String conversationId, List<String> usernames) async {
    try {
      _upsertConversation(await backend.addMembers(conversationId, usernames: usernames));
      notifyListeners();
    } catch (error) {
      if (!isAuthFailure(error)) _lastError = describeError(error);
      notifyListeners();
    }
  }

  /// Leaves a conversation (removes the caller from the member list).
  Future<void> leaveConversation(String conversationId) async {
    try {
      await backend.removeMember(conversationId);
      _forgetConversationLocal(conversationId);
    } catch (error) {
      if (!isAuthFailure(error)) _lastError = describeError(error);
      notifyListeners();
    }
  }

  /// Removes somebody else from a group; the server allows this for owners.
  Future<void> removeMember(String conversationId, {required String userId}) async {
    try {
      _upsertConversation(await backend.removeMember(conversationId, userId: userId));
      notifyListeners();
    } catch (error) {
      if (!isAuthFailure(error)) _lastError = describeError(error);
      notifyListeners();
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
    notifyListeners();
    if (!_loadedConversations.contains(conversationId)) {
      await _loadHistory(conversationId);
    }
    await markRead(conversationId);
  }

  void closeConversation(String conversationId) {
    if (_openConversationId != conversationId) return;
    _openConversationId = null;
    _stopTyping(conversationId);
    notifyListeners();
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
    notifyListeners();
    try {
      final page = await backend.listMessages(conversationId, limit: limit);
      _messages[conversationId] = page.messages.map(ChatMessage.new).toList();
      _hasOlder[conversationId] = page.hasMore;
      _loadedConversations.add(conversationId);
    } catch (error) {
      if (isAuthFailure(error)) {
        await _forgetSession();
      } else {
        _lastError = describeError(error);
      }
    } finally {
      _loadingHistory[conversationId] = false;
      notifyListeners();
    }
  }

  /// Loads the page above the oldest message we hold (scrolling up).
  Future<void> loadOlder(String conversationId) async {
    final existing = _messages[conversationId];
    if (existing == null || existing.isEmpty) return;
    if (loadingHistory(conversationId) || !hasOlder(conversationId)) return;
    _loadingHistory[conversationId] = true;
    notifyListeners();
    try {
      final oldest = existing.firstWhere((m) => !m.isPending, orElse: () => existing.first);
      if (oldest.seq == 0) return;
      final page = await backend.listMessages(conversationId, beforeSeq: oldest.seq, limit: 50);
      _messages[conversationId] = _dedupe([
        ...page.messages.map(ChatMessage.new),
        ...existing,
      ]);
      _hasOlder[conversationId] = page.hasMore;
    } catch (error) {
      if (!isAuthFailure(error)) _lastError = describeError(error);
    } finally {
      _loadingHistory[conversationId] = false;
      notifyListeners();
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
  /// The optimistic copy carries a `clientMessageId`; the stored message
  /// replaces it when the server answers. A failure keeps the bubble on screen
  /// with a retry affordance rather than losing what the user typed.
  Future<void> sendMessage(
    String conversationId, {
    required String text,
    List<Attachment> attachments = const [],
    String? replyToId,
  }) async {
    final clientMessageId = _newClientMessageId();
    final draft = Message(
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

    final list = _messages.putIfAbsent(conversationId, () => []);
    list.add(ChatMessage(draft, state: SendState.sending));
    // Move the row to the top of the list before the round trip finishes.
    final current = _conversations[conversationId];
    if (current != null) {
      _upsertConversation(current.deepCopy()..lastMessage = draft);
    }
    notifyListeners();

    await _deliver(conversationId, draft);
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
    notifyListeners();
    await _deliver(conversationId, failed.message);
  }

  Future<void> _deliver(String conversationId, Message draft) async {
    try {
      final stored = await backend.sendMessage(
        conversationId,
        text: draft.text,
        attachmentIds: draft.attachments.map((a) => a.id).toList(),
        replyToId: draft.replyToId.isEmpty ? null : draft.replyToId,
        clientMessageId: draft.clientMessageId,
      );
      _replacePending(conversationId, draft, stored);
    } catch (error) {
      if (isAuthFailure(error)) _lastError = describeError(error);
      _markFailed(conversationId, draft, describeError(error));
    }
  }

  void _replacePending(String conversationId, Message draft, Message stored) {
    final list = _messages[conversationId];
    if (list == null) return;
    final index = list.indexWhere((m) =>
        m.id == draft.id ||
        (m.message.clientMessageId.isNotEmpty && m.message.clientMessageId == stored.clientMessageId));
    if (index >= 0) {
      list[index] = ChatMessage(stored);
    } else {
      list.add(ChatMessage(stored));
    }
    _messages[conversationId] = _dedupe(list);
    final conversation = _conversations[conversationId];
    if (conversation != null) {
      _upsertConversation(conversation.deepCopy()..lastMessage = stored);
    }
    notifyListeners();
  }

  void _markFailed(String conversationId, Message draft, String error) {
    final list = _messages[conversationId];
    if (list == null) return;
    final index = list.indexWhere((m) => m.id == draft.id);
    if (index >= 0) {
      list[index] = ChatMessage(draft, state: SendState.failed, error: error);
    }
    notifyListeners();
  }

  Future<void> editMessage(String conversationId, String messageId, String text) async {
    try {
      _mergeMessage(conversationId, await backend.editMessage(messageId, text));
      notifyListeners();
    } catch (error) {
      if (!isAuthFailure(error)) _lastError = describeError(error);
      notifyListeners();
    }
  }

  Future<void> deleteMessage(String conversationId, String messageId) async {
    try {
      _mergeMessage(conversationId, await backend.deleteMessage(messageId));
      notifyListeners();
    } catch (error) {
      if (!isAuthFailure(error)) _lastError = describeError(error);
      notifyListeners();
    }
  }

  /// Adds the reaction if the user has not picked it yet, removes it if they
  /// have — one tap, one meaning.
  Future<void> toggleReaction(String conversationId, Message message, String emoji) async {
    final mine = message.reactions
        .where((reaction) => reaction.emoji == emoji)
        .any((reaction) => reaction.userIds.contains(_me?.id));
    try {
      final stored = mine
          ? await backend.removeReaction(message.id, emoji)
          : await backend.addReaction(message.id, emoji);
      _mergeMessage(conversationId, stored);
      notifyListeners();
    } catch (error) {
      if (!isAuthFailure(error)) _lastError = describeError(error);
      notifyListeners();
    }
  }

  /// Advances the read cursor and clears the unread badge.
  Future<int> markRead(String conversationId) async {
    try {
      final seq = await backend.markRead(conversationId);
      final conversation = _conversations[conversationId];
      if (conversation != null && conversation.unreadCount != 0) {
        _upsertConversation(conversation.deepCopy()..unreadCount = 0);
        notifyListeners();
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
    notifyListeners();
  }

  void _clearTyping(String conversationId, String userId) {
    final list = _typing[conversationId];
    if (list == null) return;
    final before = list.length;
    list.removeWhere((t) => t.userId == userId);
    if (list.length != before) notifyListeners();
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
        if (list.length != before) notifyListeners();
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
    _subscription = backend.subscribe().listen(
      _onEvent,
      onError: (Object _) {
        _realtimeConnected = false;
        notifyListeners();
        _scheduleReconnect();
      },
      onDone: () {
        _realtimeConnected = false;
        notifyListeners();
        _scheduleReconnect();
      },
      cancelOnError: true,
    );
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
        notifyListeners();
      case Event_Payload.contact:
        unawaited(_reloadContacts());
      case Event_Payload.notSet:
        break;
    }
  }

  void _onMessageEvent(Message message) {
    _mergeMessage(message.conversationId, message);
    final conversation = _conversations[message.conversationId];
    if (conversation != null) {
      _upsertConversation(conversation.deepCopy()..lastMessage = message);
    }
    // A message from someone else in the open thread counts as read at once,
    // the way a messenger behaves when the window is in front of you.
    if (_openConversationId == message.conversationId && message.senderId != _me?.id) {
      unawaited(markRead(message.conversationId));
    }
    notifyListeners();
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
    notifyListeners();
  }

  void _onConversationEvent(ConversationEvent event) {
    if (event.removed) {
      _conversations.remove(event.conversation.id);
      _reorderConversations();
    } else {
      _upsertConversation(event.conversation);
    }
    notifyListeners();
  }

  Future<void> _reloadContacts() async {
    try {
      contacts = await backend.listContacts();
      notifyListeners();
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
      notifyListeners();
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
      notifyListeners();
      return conversation ?? (await _findDirectWith(result.contact.user.id));
    } catch (error) {
      if (!isAuthFailure(error)) _lastError = describeError(error);
      notifyListeners();
      return null;
    }
  }

  Future<Conversation?> _findDirectWith(String userId) async {
    try {
      final conversation = await backend.createDirectConversation(userId: userId);
      _upsertConversation(conversation);
      notifyListeners();
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
      notifyListeners();
    }
  }

  Future<Invite?> createInvite({int expiresInHours = 0, int maxUses = 0}) async {
    try {
      final invite = await backend.createInvite(expiresInHours: expiresInHours, maxUses: maxUses);
      invites = [invite, ...invites];
      notifyListeners();
      return invite;
    } catch (error) {
      if (!isAuthFailure(error)) _lastError = describeError(error);
      notifyListeners();
      return null;
    }
  }

  Future<void> revokeInvite(String code) async {
    try {
      await backend.revokeInvite(code);
      invites = await backend.listInvites();
      notifyListeners();
    } catch (error) {
      if (!isAuthFailure(error)) _lastError = describeError(error);
      notifyListeners();
    }
  }

  Future<InvitePreview?> previewInvite(String code) async {
    try {
      return await backend.previewInvite(code);
    } catch (error) {
      _lastError = describeError(error);
      notifyListeners();
      return null;
    }
  }

  Future<RedeemResult?> redeemInvite(String code) async {
    try {
      final result = await backend.redeemInvite(code);
      await _reloadContacts();
      _upsertConversation(result.conversation);
      notifyListeners();
      return result;
    } catch (error) {
      _lastError = describeError(error);
      notifyListeners();
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
      notifyListeners();
    } catch (error) {
      if (!isAuthFailure(error)) _lastError = describeError(error);
      notifyListeners();
    }
  }

  // --- presentation helpers ---------------------------------------------

  /// A URL the UI can hand to an image widget.
  String fileUrl(String path) => backend.fileUrl(path);

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
