// Widget tests for the chat flow, driven against the in-memory fake backend.
//
// These cover the behaviour a person would notice: signing in, seeing the
// conversation list, opening a thread, sending a message and watching it
// appear, receiving one from someone else, and what a failed send looks like.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watch_it/watch_it.dart';

import 'package:ratatosk/src/api/backend.dart';
import 'package:ratatosk/src/app.dart';
import 'package:ratatosk/src/crypto/identity.dart';
import 'package:ratatosk/src/crypto/crypto.dart';
import 'package:ratatosk/src/crypto/manager.dart';
import 'package:ratatosk/src/crypto/message_content.dart';
import 'package:ratatosk/src/gen/ratatosk/v1/chat.pb.dart';
import 'package:ratatosk/src/gen/ratatosk/v1/keys.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart';
import 'package:ratatosk/src/crypto/session.dart';
import 'package:ratatosk/src/link_controller.dart';
import 'package:ratatosk/src/session_store.dart';
import 'package:ratatosk/src/state/app_state.dart';
import 'package:ratatosk/src/ui/chat_list_page.dart';
import 'package:ratatosk/src/ui/chat_page.dart';
import 'package:ratatosk/src/ui/settings_page.dart';
import 'package:ratatosk/src/ui/invite_sheet.dart';
import 'package:ratatosk/src/ui/theme.dart';
import 'package:ratatosk/src/ui/widgets/qr_code.dart';
import 'package:qr/qr.dart';
import 'package:ratatosk/src/ui/widgets/encrypted_image.dart';

import 'package:ratatosk/src/ui/auth_screen.dart';
import 'package:ratatosk/src/ui/google_signin.dart';

import 'fake_backend.dart';

/// The other participant, with real keys, so a test can produce messages that
/// are genuinely sealed and must be decrypted.
class Peer {
  Peer(this.identity, this.crypto);

  final DeviceIdentity identity;
  final RatatoskCrypto crypto;

  DeviceKey get record => DeviceKey(
        id: identity.deviceKeyId,
        userId: 'u2',
        identityPublicKey: identity.identityPublicKey,
        signingPublicKey: identity.signingPublicKey,
      );

  /// Seals a message body the way this device would in a direct conversation
  /// with [app].
  Future<Message> sealFor({
    required DeviceIdentity app,
    required String conversationId,
    required String text,
    required int seq,
  }) async {
    final key = await crypto.directConversationKey(
      own: identity.identityKeyPair,
      theirIdentity: crypto.identityPublic(app.identityPublicKey),
      ownFingerprint: identity.keyFingerprint,
      theirFingerprint: app.keyFingerprint,
    );
    final sealed = await crypto.seal(
      key: key,
      plaintext: MessageContent(text: text).encode(),
      aad: messageAad(conversationId: conversationId, senderDeviceKeyId: identity.deviceKeyId),
    );
    return Message(
      id: '$conversationId-peer-$seq',
      conversationId: conversationId,
      senderId: 'u2',
      seq: Int64(seq),
      createdAt: Timestamp.fromDateTime(DateTime.now().toUtc()),
      kind: MessageKind.MESSAGE_KIND_TEXT,
      ciphertext: sealed.combined,
      nonce: sealed.nonce,
      senderDeviceKeyId: identity.deviceKeyId,
      cryptoVersion: cryptoVersion,
      encrypted: true,
    );
  }
}

void main() {
  late FakeBackend backend;
  late AppState state;
  late LinkController links;
  late Peer peer;

  /// A clock the test advances by hand: typing indicators and other expiries
  /// are compared against it, so a test never has to wait for real time.
  late DateTime now;

  setUp(() async {
    backend = FakeBackend();
    now = DateTime.now();
    // Encryption runs against the in-memory key store: the widget tests cover
    // the UI, and the crypto itself has its own test file.
    final crypto = CryptoManager(
      backend: backend,
      storage: MemoryKeyStorage(),
    );
    state = AppState(backend: backend, crypto: crypto, clock: () => now);

    // The peer's own keys, generated once per test.
    final peerCrypto = RatatoskCrypto();
    peer = Peer(await _peerIdentity(peerCrypto), peerCrypto);
    // The widget tree reaches for these through get_it; registering the fake as
    // the backend is all it takes to run the UI without a network.
    di.registerSingleton<ChatBackend>(backend);
    di.registerSingleton<GoogleSignIn>(GoogleSignIn(backend: backend));
    di.registerSingleton<CryptoManager>(crypto);
    di.registerSingleton<AttachmentCache>(AttachmentCache());
    di.registerSingleton<AppState>(state);
    links = LinkController();
    di.registerSingleton<LinkController>(links);
    di.registerSingleton<SessionStore>(SessionStore());
  });

  tearDown(() async {
    state.dispose();
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
    backend.addDeviceKey(userId: userId, key: peer.record);
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

  testWidgets('adding a reaction shows it on the message', (tester) async {
    // Reported: long-pressing a message and picking an emoji added the reaction
    // (the server had it) but the bubble never showed it.
    backend.seedConversation(history: ['react to me']);
    await signIn();
    await state.openConversation('c1');
    await tester.pumpWidget(
      MaterialApp(theme: RatatoskTheme.light(), home: const ChatPage(conversationId: 'c1')),
    );
    await settle(tester);

    expect(find.text('👍'), findsNothing);
    // The gesture: long-press the bubble, then tap the emoji in the sheet.
    await tester.longPress(find.text('react to me'));
    await settle(tester);
    expect(find.text('👍'), findsOneWidget, reason: 'the reaction sheet did not open');
    await tester.tap(find.text('👍'));
    await settle(tester);

    // The sheet must be *gone* before counting emoji: while it is open it holds
    // one itself, so a bare `find.text('👍')` cannot tell the chip apart from the
    // sheet — which made this test pass even when no chip rendered.
    expect(find.text('Reply'), findsNothing, reason: 'the action sheet is still open');
    expect(find.text('Delete'), findsNothing, reason: 'the action sheet is still open');
    expect(find.text('👍'), findsOneWidget,
        reason: 'the reaction is in the state but nothing was drawn for it');
    expect(state.messages('c1').single.message.reactions.single.emoji, '👍');
  });

  testWidgets('a refused reaction is reported instead of silently ignored', (tester) async {
    // The reported symptom was "nothing happens at all". A refused request looked
    // exactly like that, because the error was recorded in the manager and shown
    // on no screen at all.
    backend.seedConversation(history: ['react to me']);
    backend.failNextReaction = true;
    await signIn();
    await state.openConversation('c1');
    await tester.pumpWidget(
      MaterialApp(theme: RatatoskTheme.light(), home: const ChatPage(conversationId: 'c1')),
    );
    await settle(tester);

    await tester.longPress(find.text('react to me'));
    await settle(tester);
    await tester.tap(find.text('👍'));
    await settle(tester);

    expect(find.byType(SnackBar), findsOneWidget,
        reason: 'a failed reaction was swallowed with no feedback');
    expect(state.messages('c1').single.message.reactions, isEmpty);
  });

  testWidgets('a reaction chip shows a count and names who reacted on hover',
      (tester) async {
    backend.seedConversation(history: ['react to me']);
    await signIn();
    await state.openConversation('c1');
    await tester.pumpWidget(
      MaterialApp(theme: RatatoskTheme.light(), home: const ChatPage(conversationId: 'c1')),
    );
    await settle(tester);

    await tester.longPress(find.text('react to me'));
    await settle(tester);
    await tester.tap(find.text('👍').first);
    await settle(tester);

    // No number for a single reaction: it would only restate the emoji beside it.
    expect(find.text('1'), findsNothing,
        reason: 'a lone reaction is showing a count of 1');

    // Hovering names who reacted, which is what the tooltip is for — an emoji alone
    // cannot say whether it was the person you were talking to.
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    await gesture.moveTo(tester.getCenter(find.byType(Tooltip).first));
    await tester.pump(const Duration(milliseconds: 600));
    await settle(tester);
    expect(find.textContaining('reacted'), findsOneWidget,
        reason: 'no tooltip naming who reacted');
    await gesture.removePointer();
  });

  testWidgets('reactions overlap the message instead of sitting below it',
      (tester) async {
    // The chips are lifted onto the bubble's edge, so their top must be above the
    // bubble's bottom — a gap would mean they read as the next item in the list.
    backend.seedConversation(history: ['react to me']);
    await signIn();
    await state.openConversation('c1');
    await tester.pumpWidget(
      MaterialApp(theme: RatatoskTheme.light(), home: const ChatPage(conversationId: 'c1')),
    );
    await settle(tester);

    await tester.longPress(find.text('react to me'));
    await settle(tester);
    await tester.tap(find.text('👍').first);
    await settle(tester);

    // The bubble, not the text: the bubble also carries a timestamp row below the
    // text, so the text's bottom is not the edge the chip should overlap.
    final bubble = tester.getRect(find.ancestor(
      of: find.text('react to me'),
      matching: find.byType(GestureDetector),
    ).first);
    final chip = tester.getRect(find.byType(Tooltip).first);
    expect(chip.top, lessThan(bubble.bottom),
        reason: 'the chip is not overlapping the message it relates to '
            '(chip top ${chip.top}, bubble bottom ${bubble.bottom})');
  });

  testWidgets('a reaction sits on the side its message is on', (tester) async {
    // Reported: every reaction was on the left, because the row was aligned
    // bottomLeft for everybody. A reaction belongs on the side of the message it
    // relates to, so my own must be on the right.
    backend.seedConversation(history: ['theirs']);
    // A message from me, seeded rather than sent: sending needs the peer to have
    // encryption keys, which is a real rule and not what this test is about.
    backend.seedOwnMessage('c1', 'mine');
    await signIn();
    await state.openConversation('c1');
    await tester.pumpWidget(
      MaterialApp(theme: RatatoskTheme.light(), home: const ChatPage(conversationId: 'c1')),
    );
    await settle(tester);

    // React to the message *I* sent, which must land on the right.
    await tester.longPress(find.text('mine'));
    await settle(tester);
    await tester.tap(find.text('👍').first);
    await settle(tester);

    // Measured by the emoji itself: the page also carries tooltips on its icon
    // buttons, so `find.byType(Tooltip)` is not specific to reaction chips.
    final screenWidth = tester.getSize(find.byType(MaterialApp)).width;
    final myChip = tester.getRect(find.text('👍'));
    expect(myChip.center.dx, greaterThan(screenWidth / 2),
        reason: 'a reaction on my own message is not on the right side '
            '(center ${myChip.center.dx}, half-width ${screenWidth / 2})');

    // And a reaction to the other person's message stays on the left.
    await tester.longPress(find.text('theirs'));
    await settle(tester);
    await tester.tap(find.text('❤️').first);
    await settle(tester);

    final theirChip = tester.getRect(find.text('❤️'));
    expect(theirChip.center.dx, lessThan(screenWidth / 2),
        reason: 'a reaction on their message is not on the left side '
            '(center ${theirChip.center.dx}, half-width ${screenWidth / 2})');
  });

  testWidgets('a second reaction to the same message shows a count', (tester) async {
    backend.seedConversation(history: ['react to me']);
    await signIn();
    await state.openConversation('c1');
    await tester.pumpWidget(
      MaterialApp(theme: RatatoskTheme.light(), home: const ChatPage(conversationId: 'c1')),
    );
    await settle(tester);

    // Somebody else reacts first, then I add the same emoji: the number now says how
    // many people, which is the only time it carries information.
    final message = state.messages('c1').single;
    await state.toggleReaction('c1', message.message, '👍');
    backend.seedReactionFrom('u-peer', message.message.id, '👍');
    await state.refresh();
    await settle(tester);

    expect(find.text('2'), findsOneWidget,
        reason: 'two people reacted but no count is shown');
  });

  testWidgets('signing up with an invitation sends the code', (tester) async {
    // The bug behind "invites were expired": the code was handed to this screen and
    // never used, so sign-up created the account without it and a *separate* redemption
    // spent the single use — leaving a one-use link exhausted by the person who was
    // meant to be joining.
    await signIn();
    await tester.pumpWidget(MaterialApp(
      theme: RatatoskTheme.light(),
      home: const AuthScreen(),
    ));
    await tester.pumpAndSettle();

    links.submitCode('joinme1');
    await tester.pumpAndSettle();

    // Switch to registration, fill it in, submit.
    await tester.tap(find.text('Create a new account'));
    await tester.pumpAndSettle();
    // Registration adds a name field, so three means the form switched. Asserted
    // because the rest of the test is meaningless if it did not.
    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(3),
        reason: 'the form did not switch to registration');
    await tester.enterText(fields.at(1), 'newcomer');
    await tester.enterText(fields.at(2), 'a good password');
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pumpAndSettle();

    expect(backend.registeredInvites, isNotEmpty,
        reason: 'registration did not carry the invitation at all');
    expect(backend.registeredInvites.last, 'joinme1',
        reason: 'registration dropped the invitation code');
  });

  testWidgets('profile dialog fits phone width with keyboard inset', (tester) async {
    await signIn();
    tester.view.physicalSize = const Size(390, 650);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(theme: RatatoskTheme.light(),
      home: Scaffold(body: Builder(builder: (context) => TextButton(
        onPressed: () => showProfileDialog(context), child: const Text('Edit'))))));
    await tester.tap(find.text('Edit'));
    await settle(tester);
    expect(find.text('Edit profile'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Cancel'));
    await settle(tester);
  });

  test('incoming direct message uses the actual sender, not oldest device', () async {
    backend.seedConversation();
    await signIn();
    await seedPeerKey(); // Older device is first in the directory.
    final newerCrypto = RatatoskCrypto();
    final newer = Peer(await _peerIdentity(newerCrypto, id: 'k-newer'), newerCrypto);
    backend.addDeviceKey(userId: 'u2', key: newer.record);
    await state.refreshConversationKeys('c1');
    final sealed = await newer.sealFor(app: state.crypto.identity!,
        conversationId: 'c1', text: 'from the newer phone', seq: 1);
    final opened = await state.crypto.decryptMessage(
        conversation: backend.conversations['c1']!, message: sealed, ownMessage: false);
    expect(opened.ok, isTrue, reason: opened.unreadable);
    expect(opened.text, 'from the newer phone');
  });

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
    // Exactly one entry: the send response and the stream echo are the same
    // message, and showing both would leave a stray unreadable bubble.
    expect(state.messages('c1'), hasLength(1));
    expect(state.messages('c1').single.state, SendState.sent);
    // The plaintext is still readable on this device.
    expect(find.text('this one is sealed'), findsOneWidget);
    expect(find.text('Encrypted'), findsNothing, reason: 'no stray unreadable bubble');
  });

  testWidgets('a message pulled in by catch-up is decrypted, not left as a placeholder', (tester) async {
    // The catch-up path (reconnect, or re-opening a loaded thread) merges
    // messages from the server. It used to skip decryption, so those bubbles sat
    // at "Opening…" forever while the ones beside them were readable.
    backend.seedConversation(history: ['already here']);
    await signIn();
    await seedPeerKey();
    await state.openConversation('c1');
    expect(state.bodyOf(state.messages('c1').single).text, 'already here');

    // The peer sends a *sealed* message while the app is not listening, then a
    // reconnect pulls it in. It can only become readable by being decrypted.
    final sealed = await peer.sealFor(
      app: state.crypto.identity!,
      conversationId: 'c1',
      text: 'sent while you were away',
      seq: 2,
    );
    backend.deliverSilently('c1', sealed);
    await state.refresh();
    await settle(tester, frames: 5);

    final bodies = state.messages('c1').map(state.bodyOf).toList();
    expect(bodies.map((b) => b.text), contains('sent while you were away'));
    expect(bodies.every((b) => b.ok), isTrue, reason: 'no bubble may stay unreadable');
    expect(bodies.map((b) => b.unreadable), everyElement(isNull));
  });

  testWidgets('an unopenable message says why instead of spinning', (tester) async {
    // A sealed message this device has no key for must explain itself. Showing
    // "Opening…" for it is worse than useless: it looks like a stuck app.
    backend.seedConversation();
    await signIn();
    await seedPeerKey();
    // Sealed by a third device whose key this app was never given, so the
    // attempt must fail and the bubble has to say so.
    final strangerCrypto = RatatoskCrypto();
    final stranger = Peer(await _peerIdentity(strangerCrypto), strangerCrypto);
    final sealed = await stranger.sealFor(
      app: state.crypto.identity!,
      conversationId: 'c1',
      text: 'not for this device',
      seq: 1,
    );
    backend.deliverSilently('c1', sealed);
    await state.openConversation('c1');
    await settle(tester, frames: 5);

    final body = state.bodyOf(state.messages('c1').last);
    expect(body.ok, isFalse);
    expect(body.unreadable, isNotNull);
    expect(body.unreadable, isNot('Opening…'), reason: 'a failed attempt must not look in-progress');
  });

  group('the sender\'s own message arrives twice', () {
    // A server pushes the stored message to every member, sender included, so a
    // send comes back both as the response and on the stream. Whichever lands
    // first, the thread must end up with one bubble holding the plaintext.
    for (final echoFirst in [true, false]) {
      final ordering = echoFirst ? 'stream first' : 'response first';
      testWidgets('one bubble when the $ordering', (tester) async {
        backend.seedConversation(id: 'g1', kind: 'group', title: 'Bridge Crew');
        await signIn();
        await state.refreshConversationKeys('g1');
        backend.echoBeforeReturn = echoFirst;

        await state.sendMessage('g1', text: 'the span is in');
        await settle(tester, frames: 5);

        final entries = state
            .messages('g1')
            .where((m) => m.message.kind != MessageKind.MESSAGE_KIND_SYSTEM)
            .toList();
        expect(entries, hasLength(1), reason: 'one send, one bubble');
        expect(entries, hasLength(backend.messages['g1']!.length),
            reason: 'the thread matches what the server holds');
        expect(state.bodyOf(entries.single).text, 'the span is in');
        expect(state.bodyOf(entries.single).unreadable, isNull);
        expect(entries.single.isPending, isFalse);
        // Nothing left behind in the composer's list that cannot be read.
        for (final entry in state.messages('g1')) {
          expect(state.bodyOf(entry).unreadable, isNot('Encrypted'));
        }
      });
    }
  });

  testWidgets('the invite sheet shows a scannable QR of the link', (tester) async {
    await signIn();
    await tester.pumpWidget(
      MaterialApp(theme: RatatoskTheme.light(), home: const Scaffold(body: InviteSheet())),
    );
    await settle(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Create a link'));
    await settle(tester, frames: 10);

    final qr = find.byType(QrCodeView);
    expect(qr, findsOneWidget);

    // It must encode the *link*, not the bare code: a phone's camera app has to
    // be able to open it without knowing anything about Ratatosk.
    final widget = tester.widget<QrCodeView>(qr);
    expect(widget.data, startsWith('http://fake.test/join/'));
    expect(widget.data, isNot(contains(' ')));

    // A real QR image comes out of the encoder, and it is big enough to scan.
    final image = QrImage(QrCode(
      payload: QrPayload.fromString(widget.data),
      errorCorrectLevel: QrErrorCorrectLevel.medium,
    ));
    expect(image.moduleCount, greaterThan(20));
    expect(tester.getSize(qr).width, greaterThanOrEqualTo(140));

    // The link is still shown as text, and the buttons still work: the QR is an
    // addition, not a replacement.
    expect(find.textContaining('/join/'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Copy link'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Share'), findsOneWidget);
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

/// A device identity for a peer, with a fixed device key id.
Future<DeviceIdentity> _peerIdentity(RatatoskCrypto crypto, {String id = 'k-peer'}) async {
  final identityPair = await crypto.newIdentityKeyPair();
  final signingPair = await crypto.newSigningKeyPair();
  final identityPublic = await crypto.publicKeyBytes(identityPair);
  final signingPublic = await crypto.publicKeyBytes(signingPair);
  return DeviceIdentity(
    crypto: crypto,
    identityKeyPair: identityPair,
    signingKeyPair: signingPair,
    identityPublicKey: identityPublic,
    signingPublicKey: signingPublic,
    deviceKeyId: id,
    fingerprint: await crypto.fingerprint(
      deviceKeyId: id,
      identityPublicKey: identityPublic,
      signingPublicKey: signingPublic,
    ),
    keyFingerprint: await crypto.keyFingerprint(
      identityPublicKey: identityPublic,
      signingPublicKey: signingPublic,
    ),
  );
}
