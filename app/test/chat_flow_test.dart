// Widget tests for the chat flow, driven against the in-memory fake backend.
//
// These cover the behaviour a person would notice: signing in, seeing the
// conversation list, opening a thread, sending a message and watching it
// appear, receiving one from someone else, and what a failed send looks like.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watch_it/watch_it.dart';

import 'dart:typed_data';

import 'package:ratatosk/src/api/backend.dart';
import 'package:ratatosk/src/app.dart';
import 'package:ratatosk/src/crypto/identity.dart';
import 'package:ratatosk/src/crypto/manager.dart';
import 'package:ratatosk/src/gen/ratatosk/v1/chat.pb.dart';
import 'package:ratatosk/src/gen/ratatosk/v1/keys.pb.dart';
import 'package:ratatosk/src/link_controller.dart';
import 'package:ratatosk/src/session_store.dart';
import 'package:ratatosk/src/state/app_state.dart';
import 'package:ratatosk/src/ui/chat_list_page.dart';
import 'package:ratatosk/src/ui/chat_page.dart';
import 'package:ratatosk/src/ui/theme.dart';
import 'package:ratatosk/src/ui/widgets/encrypted_image.dart';

import 'fake_backend.dart';

void main() {
  late FakeBackend backend;
  late AppState state;

  /// A clock the test advances by hand: typing indicators and other expiries
  /// are compared against it, so a test never has to wait for real time.
  late DateTime now;

  setUp(() {
    backend = FakeBackend();
    now = DateTime.now();
    // Encryption runs against the in-memory key store: the widget tests cover
    // the UI, and the crypto itself has its own test file.
    final crypto = CryptoManager(
      backend: backend,
      storage: MemoryKeyStorage(),
    );
    state = AppState(backend: backend, crypto: crypto, clock: () => now);
    // The widget tree reaches for these through get_it; registering the fake as
    // the backend is all it takes to run the UI without a network.
    di.registerSingleton<ChatBackend>(backend);
    di.registerSingleton<CryptoManager>(crypto);
    di.registerSingleton<AttachmentCache>(AttachmentCache());
    di.registerSingleton<AppState>(state);
    di.registerSingleton<LinkController>(LinkController());
    di.registerSingleton<SessionStore>(SessionStore());
  });

  tearDown(() async {
    await di.reset();
    backend.dispose();
  });

  /// Signs the state in without going through the server.
  Future<void> signIn() async {
    await state.bootstrap(savedToken: 'fake-token');
  }

  /// Publishes the other participant's device key and lets the app see it, so
  /// the conversation can be encrypted to. Sending without it is *refused*, so
  /// every test that sends has to do this — that is the point of the refusal.
  Future<void> seedPeerKey({String userId = 'u2'}) async {
    backend.addDeviceKey(
      userId: userId,
      key: DeviceKey(
        id: 'k-$userId',
        userId: userId,
        identityPublicKey: Uint8List.fromList(List<int>.filled(32, 7)),
        signingPublicKey: Uint8List.fromList(List<int>.filled(32, 9)),
      ),
    );
    await state.refreshConversationKeys('c1');
  }

  /// Pumps a bounded number of frames.
  ///
  /// `pumpAndSettle` is the wrong tool here: a `CircularProgressIndicator`
  /// animates forever, so the tree is never quiescent while one is on screen
  /// (the splash, or a thread whose history is still loading).
  Future<void> settle(WidgetTester tester, {int frames = 25}) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  testWidgets('sign-in screen accepts credentials and shows the chat list', (tester) async {
    // No stored token: the bootstrap finishes on the sign-in screen.
    await state.bootstrap();
    await tester.pumpWidget(MaterialApp(theme: RatatoskTheme.light(), home: const AppGate()));
    await settle(tester);

    expect(find.text('Ratatosk'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);

    // Entering both fields is what enables a successful sign-in.
    await tester.enterText(find.widgetWithText(TextField, 'Username'), 'ada');
    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'password123');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await settle(tester);

    // The signed-in shell is on screen.
    expect(find.text('Chats'), findsOneWidget);
    expect(find.text('No conversations yet'), findsOneWidget);
  });

  testWidgets('the conversation list shows a row with peer, preview and unread', (tester) async {
    backend.seedConversation(history: ['are you around?']);
    backend.conversations['c1']!.unreadCount = 2;
    await signIn();

    await tester.pumpWidget(MaterialApp(theme: RatatoskTheme.light(), home: const ChatListPage()));
    await settle(tester);

    expect(find.text('Grace Hopper'), findsOneWidget);
    expect(find.text('are you around?'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('opening a thread shows history and sends a message', (tester) async {
    backend.seedConversation(history: ['first from grace']);
    await signIn();
    await seedPeerKey();

    await tester.pumpWidget(
      MaterialApp(theme: RatatoskTheme.light(), home: const ChatPage(conversationId: 'c1')),
    );
    await settle(tester);

    expect(find.text('first from grace'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'hello back');
    await tester.pump();
    await tester.tap(find.byTooltip('Send'));
    await tester.pump();

    // The optimistic bubble appears before the round trip completes, then is
    // replaced by the stored message.
    expect(find.text('hello back'), findsOneWidget);
    await settle(tester);
    expect(find.text('hello back'), findsOneWidget);
    expect(state.messages('c1').every((m) => !m.isPending), isTrue);

    // The stored record carries the seal, not the words: this is what the
    // server holds, and it is why the bubble is rendered from the local
    // decryption rather than from the message on the wire.
    final stored = state.messages('c1').last;
    expect(stored.message.encrypted, isTrue);
    expect(stored.message.text, isEmpty);
    expect(stored.message.ciphertext, isNotEmpty);
    expect(state.bodyOf(stored).text, 'hello back');
  });

  testWidgets('a message from someone else appears while the thread is open', (tester) async {
    backend.seedConversation(history: ['hello']);
    await signIn();

    await tester.pumpWidget(
      MaterialApp(theme: RatatoskTheme.light(), home: const ChatPage(conversationId: 'c1')),
    );
    await settle(tester);

    backend.deliverFromPeer('c1', 'are you there?');
    await settle(tester, frames: 3);

    expect(find.text('are you there?'), findsOneWidget);
  });

  testWidgets('a failed send stays on screen with a retry', (tester) async {
    backend.seedConversation();
    await signIn();
    await seedPeerKey();
    backend.failNextSend = true;

    await tester.pumpWidget(
      MaterialApp(theme: RatatoskTheme.light(), home: const ChatPage(conversationId: 'c1')),
    );
    await settle(tester);

    await tester.enterText(find.byType(TextField).last, 'this will fail');
    await tester.pump();
    await tester.tap(find.byTooltip('Send'));
    await settle(tester);

    // The text is not lost, and the user is told what happened.
    expect(find.text('this will fail'), findsOneWidget);
    expect(find.text('Not sent'), findsOneWidget);
    expect(state.messages('c1').single.state, SendState.failed);

    // Retrying succeeds because the fake only fails once.
    await tester.tap(find.text('Retry'));
    await settle(tester);
    expect(find.text('Not sent'), findsNothing);
    expect(state.messages('c1').single.state, SendState.sent);
  });

  testWidgets('a message to a peer with no keys is refused, never sent in the clear', (tester) async {
    // The peer has no device key: a script client, or somebody who has not
    // opened an app yet. Encryption is the only path, so the send must fail
    // with an explanation rather than fall back to plaintext — a silent
    // downgrade is the one failure a user would never notice.
    backend.seedConversation(history: ['hello']);
    await signIn();
    // Encryption is set up on this device; it is the *peer* who has no key.
    expect(state.encryptionReady, isTrue);
    final conversation = state.conversation('c1')!;
    expect(state.canEncryptConversation('c1'), isFalse);
    expect(di<CryptoManager>().peerWithoutKey(conversation), 'Grace Hopper');

    await tester.pumpWidget(
      MaterialApp(theme: RatatoskTheme.light(), home: const ChatPage(conversationId: 'c1')),
    );
    await settle(tester);

    // The badge reports the truth instead of showing a padlock.
    expect(find.byTooltip('Not encrypted: this contact has no encryption keys yet — tap for details'),
        findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'this must not go out in the clear');
    await tester.pump();
    await tester.tap(find.byTooltip('Send'));
    await settle(tester);

    // Nothing new reached the backend.
    expect(backend.sentPlaintext, isEmpty);
    expect(state.lastError, contains('has not set up encryption yet'));
  });

  testWidgets('a conversation with a keyed peer sends sealed, not plain', (tester) async {
    // The mirror of the test above: with the peer's device key published, the
    // send succeeds and the body goes out sealed — the fake never sees it in
    // the clear.
    backend.seedConversation();
    await signIn();
    await seedPeerKey();

    await tester.pumpWidget(
      MaterialApp(theme: RatatoskTheme.light(), home: const ChatPage(conversationId: 'c1')),
    );
    await settle(tester);
    await tester.enterText(find.byType(TextField).last, 'this one is sealed');
    await tester.pump();
    await tester.tap(find.byTooltip('Send'));
    await settle(tester);

    expect(backend.sentPlaintext, isEmpty, reason: 'a sealed send must not put text on the wire');
    expect(backend.sealedSends, hasLength(1));
    expect(state.messages('c1').single.state, SendState.sent);
    // The plaintext is still readable on this device.
    expect(find.text('this one is sealed'), findsOneWidget);
  });

  testWidgets('the connection badge clears as soon as the stream is open', (tester) async {
    backend.seedConversation();
    await signIn();
    await seedPeerKey();

    await tester.pumpWidget(MaterialApp(theme: RatatoskTheme.light(), home: const ChatListPage()));
    await settle(tester);

    // A silent stream is a healthy stream: with no events arriving, the badge
    // must still report a live connection rather than sitting on "Reconnecting…".
    expect(state.realtimeConnected, isTrue);
    expect(find.textContaining('Reconnecting'), findsNothing);
  });

  testWidgets('typing indicators appear and expire', (tester) async {
    backend.seedConversation();
    await signIn();

    await tester.pumpWidget(
      MaterialApp(theme: RatatoskTheme.light(), home: const ChatPage(conversationId: 'c1')),
    );
    await settle(tester);

    backend.emit(Event(
      // The state layer ignores its own typing events, so this uses a peer id.
      typing: TypingEvent(
        conversationId: 'c1',
        userId: 'u2',
        displayName: 'Grace Hopper',
        typing: true,
      ),
    ));
    await settle(tester, frames: 3);

    expect(state.typingIn('c1').map((t) => t.displayName), contains('Grace Hopper'));
    expect(find.textContaining('Grace Hopper is typing'), findsOneWidget);

    // The indicator expires on its own rather than sticking forever: move the
    // clock past its lifetime and let the sweep run.
    now = now.add(AppState.typingLifetime + const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 3));
    await settle(tester, frames: 3);
    expect(find.textContaining('is typing'), findsNothing);
  });
}

