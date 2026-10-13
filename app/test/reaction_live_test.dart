// The reaction flow, driven through the REAL widgets against a REAL server.
//
// Every other test stops one step short of this. The widget tests use the fake
// backend, whose addReaction returns the very object it mutated. The interop tests
// use the real backend but call it directly, with no widgets. So the combination a
// user actually experiences — real transport, real widgets, the emoji sheet — was
// never run, which is where "I pick a reaction and nothing happens" could hide.
//
// Starts a server itself, so it needs no setup:
//
//	go run ./cmd/ratatoskd --addr 127.0.0.1:8199 --data /tmp/reaction-live
//	RATATOSK_URL=http://127.0.0.1:8199 flutter test test/reaction_live_test.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ratatosk/src/api/backend.dart';
import 'package:ratatosk/src/api/connect_backend.dart';
import 'package:ratatosk/src/crypto/identity.dart';
import 'package:ratatosk/src/crypto/manager.dart';
import 'package:ratatosk/src/state/app_state.dart';
import 'package:ratatosk/src/ui/chat_page.dart';
import 'package:ratatosk/src/ui/theme.dart';
import 'package:watch_it/watch_it.dart';

void main() {
  final baseUrl = Uri.parse(
    Platform.environment['RATATOSK_URL'] ?? 'http://127.0.0.1:8199',
  );
  late bool serverUp;
  late ConnectBackend backend;
  late AppState state;
  late String conversationId;

  setUpAll(() async {
    serverUp = await _isReachable(baseUrl);
    if (!serverUp) {
      // ignore: avoid_print
      print('ratatosk server not reachable at $baseUrl — skipping live UI tests');
    }
  });

  setUp(() async {
    if (!serverUp) return;
    backend = ConnectBackend(baseUrl: baseUrl);
    final stamp = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final me = await backend.register(
      username: 'rui$stamp',
      password: 'correct horse battery',
      displayName: 'Reaction UI',
    );
    backend.setToken(me.token);
    final peer = await backend.register(
      username: 'ruj$stamp',
      password: 'correct horse battery',
      displayName: 'Peer',
    );
    final peerBackend = ConnectBackend(baseUrl: baseUrl)..setToken(peer.token);

    final conversation =
        await backend.createDirectConversation(username: peer.user.username);
    conversationId = conversation.id;
    // The peer sends, so the reader is the *other* side — as in the report.
    await peerBackend.sendMessage(conversation.id, text: 'react to this please');

    state = AppState(
      backend: backend,
      crypto: CryptoManager(backend: backend, storage: MemoryKeyStorage()),
    );
    di.registerSingleton<ChatBackend>(backend);
    di.registerSingleton<AppState>(state);
    await state.bootstrap(savedToken: me.token);
    await state.openConversation(conversation.id);
  });

  tearDown(() async {
    if (!serverUp) return;
    state.dispose();
    await di.reset();
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('picking an emoji from the sheet puts a chip on the message',
      (tester) async {
    if (!serverUp) return;
    await tester.pumpWidget(MaterialApp(
      theme: RatatoskTheme.light(),
      home: const ChatPage(conversationId: 'placeholder'),
    ));
    await tester.pumpWidget(MaterialApp(
      theme: RatatoskTheme.light(),
      home: ChatPage(conversationId: conversationId),
    ));
    await settle(tester);

    // The message is there and carries no reaction yet.
    expect(find.text('react to this please'), findsOneWidget);
    expect(find.text('👍'), findsNothing);

    // The gesture a user makes: press and hold the bubble.
    await tester.longPress(find.text('react to this please'));
    await settle(tester);
    expect(find.text('👍'), findsOneWidget,
        reason: 'the action sheet did not open, so there is nothing to pick');

    // Pick an emoji.
    await tester.tap(find.text('👍'));
    await settle(tester);

    // The sheet must be gone before counting: while it is open it holds an emoji
    // of its own, so a bare count cannot tell a chip from the sheet.
    expect(find.text('Reply'), findsNothing, reason: 'the sheet never closed');
    expect(find.text('👍'), findsOneWidget,
        reason: 'the sheet closed with no chip on the message — the reported bug');

    // And it is really stored, not just drawn: a fresh read from the server must
    // carry it, which is also what makes it survive a reload.
    final page = await backend.listMessages(conversationId);
    final stored = page.messages.last;
    expect(stored.reactions, isNotEmpty,
        reason: 'the reaction never reached the server');
    expect(stored.reactions.single.emoji, '👍');
  });

  testWidgets('a failed reaction says so instead of doing nothing', (tester) async {
    if (!serverUp) return;
    await tester.pumpWidget(MaterialApp(
      theme: RatatoskTheme.light(),
      home: ChatPage(conversationId: conversationId),
    ));
    await settle(tester);

    // Take the session away behind the app's back: the next call fails the way a
    // refused one does.
    backend.setToken('not-a-valid-token');
    await tester.longPress(find.text('react to this please'));
    await settle(tester);
    await tester.tap(find.text('👍'));
    await settle(tester);

    expect(find.byType(SnackBar), findsOneWidget,
        reason: 'a rejected reaction was silent, which is the reported symptom');
  });
}

Future<bool> _isReachable(Uri url) async {
  try {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 2);
    final request = await client.getUrl(url.replace(path: '/healthz'));
    final response = await request.close();
    await response.drain<void>();
    client.close();
    return response.statusCode == 200;
  } catch (_) {
    return false;
  }
}
