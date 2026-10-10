// Widget tests for the chat flow, driven against the in-memory fake backend.
//
// These cover the behaviour a person would notice: signing in, seeing the
// conversation list, opening a thread, sending a message and watching it
// appear, receiving one from someone else, and what a failed send looks like.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watch_it/watch_it.dart';

import 'package:ratatosk/src/api/backend.dart';
import 'package:ratatosk/src/app.dart';
import 'package:ratatosk/src/gen/ratatosk/v1/chat.pb.dart';
import 'package:ratatosk/src/link_controller.dart';
import 'package:ratatosk/src/session_store.dart';
import 'package:ratatosk/src/state/app_state.dart';
import 'package:ratatosk/src/ui/chat_list_page.dart';
import 'package:ratatosk/src/ui/chat_page.dart';
import 'package:ratatosk/src/ui/theme.dart';

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
    state = AppState(backend: backend, clock: () => now);
    // The widget tree reaches for these through get_it; registering the fake as
    // the backend is all it takes to run the UI without a network.
    di.registerSingleton<ChatBackend>(backend);
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
    expect(state.messages('c1').map((m) => m.message.text), contains('hello back'));
    expect(state.messages('c1').every((m) => !m.isPending), isTrue);
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
