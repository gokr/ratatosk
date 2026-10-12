// End-to-end test of the Dart client against a running Ratatosk server.
//
// This is the test that proves the wire actually works: the app's real
// [ConnectBackend] (Connect protocol, generated clients, bearer interceptor,
// server-streaming Subscribe) talking to a real `ratatoskd`. Everything else in
// the app's test suite runs against fakes; this one does not.
//
// Start a server first, then run it:
//
//	make run-server            # in another terminal
//	flutter test test/backend_interop_test.dart
//
// RATATOSK_URL overrides the address (default http://localhost:8080). The test
// skips itself when nothing is listening, so it never breaks a plain
// `flutter test` on a machine without the server running.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ratatosk/src/api/connect_backend.dart';
import 'package:ratatosk/src/crypto/identity.dart';
import 'package:ratatosk/src/crypto/manager.dart';
import 'package:ratatosk/src/crypto/message_content.dart';
import 'package:ratatosk/src/gen/ratatosk/v1/chat.pb.dart';
import 'package:ratatosk/src/gen/ratatosk/v1/common.pb.dart';
import 'package:ratatosk/src/state/app_state.dart';

void main() {
  final baseUrl = Uri.parse(
    Platform.environment['RATATOSK_URL'] ?? 'http://localhost:8080',
  );

  late bool serverUp;
  late ConnectBackend backend;

  setUpAll(() async {
    serverUp = await _isReachable(baseUrl);
    if (!serverUp) {
      // ignore: avoid_print
      print('ratatosk server not reachable at $baseUrl — skipping interop tests');
    }
  });

  setUp(() {
    backend = ConnectBackend(baseUrl: baseUrl);
  });

  /// A unique handle per run, so repeated runs against one server do not clash.
  String handle(String prefix) => '$prefix${Random().nextInt(1 << 32)}';

  test('register, sign in and identify the caller', () async {
    if (!serverUp) return;
    final username = handle('dart');
    final result = await backend.register(
      username: username,
      password: 'password123',
      displayName: 'Dart Client',
    );
    expect(result.token, isNotEmpty);
    expect(result.user.username, username);
    expect(result.user.displayName, 'Dart Client');
    expect(result.user.accentColor, isNotEmpty);

    backend.setToken(result.token);
    final me = await backend.getMe();
    expect(me.id, result.user.id);

    // Signing in again yields a working token too.
    final fresh = ConnectBackend(baseUrl: baseUrl);
    final login = await fresh.login(username: username, password: 'password123');
    expect(login.user.id, result.user.id);
    fresh.setToken(login.token);

    // A wrong password is refused with the documented code.
    await expectLater(
      ConnectBackend(baseUrl: baseUrl).login(username: username, password: 'nope'),
      throwsA(isA<Object>()),
    );
  });

  test('a full conversation: send, stream, edit, react, delete', () async {
    if (!serverUp) return;
    final ada = await _newClient(baseUrl, handle('ada'), 'Ada Lovelace');
    final grace = await _newClient(baseUrl, handle('grace'), 'Grace Hopper');

    // Ada opens a stream first: everything below has to arrive on it without
    // polling, which is the part that would silently break if the streaming
    // transport were wrong.
    final events = <Event>[];
    final subscription = ada.backend.subscribe().listen(events.add);
    // Cancelling a live server stream does not complete while its HTTP response
    // is open, so it is not awaited: the subscription stops delivering either
    // way, and the test does not hang on teardown.
    addTearDown(() => unawaited(subscription.cancel()));

    await _waitFor(events, (e) => e.hasHello(), 'the hello frame');
    expect(events.first.hello.user.id, ada.user.id);

    // Grace streams before anything is sent: the stream starts at "now" (the
    // client reconciles older history with ListMessages), so subscribing after
    // the send would legitimately see nothing.
    final graceEvents = <Event>[];
    final graceSub = grace.backend.subscribe().listen(graceEvents.add);
    addTearDown(() => unawaited(graceSub.cancel()));
    await _waitFor(graceEvents, (e) => e.hasHello(), 'grace hello');

    final conversation = await ada.backend.createDirectConversation(username: grace.user.username);
    expect(conversation.kind, 'direct');
    expect(conversation.title, 'Grace Hopper');
    expect(conversation.hasPeer(), isTrue);

    // Grace also hears about the conversation itself, so a client can add the
    // row without reloading the list.
    await _waitFor(
      graceEvents,
      (e) => e.hasConversation() && e.conversation.conversation.id == conversation.id,
      'the new conversation on grace\'s stream',
    );

    final sent = await ada.backend.sendMessage(
      conversation.id,
      text: 'hello over connect',
      clientMessageId: 'interop-1',
    );
    expect(sent.seq.toInt(), 1);
    expect(sent.text, 'hello over connect');

    await _waitFor(
      graceEvents,
      (e) => e.hasMessage() && e.message.message.text == 'hello over connect',
      'the message on grace\'s stream',
    );

    // Retrying with the same client_message_id must not duplicate.
    final again = await ada.backend.sendMessage(
      conversation.id,
      text: 'hello over connect',
      clientMessageId: 'interop-1',
    );
    expect(again.id, sent.id);
    final page = await grace.backend.listMessages(conversation.id);
    expect(page.messages.length, 1);

    // Unread, then read.
    final mine = await grace.backend.listConversations();
    expect(mine.first.unreadCount, 1);
    await grace.backend.markRead(conversation.id);
    final afterRead = await grace.backend.listConversations();
    expect(afterRead.first.unreadCount, 0);

    // Edit, react, delete.
    final edited = await ada.backend.editMessage(sent.id, 'hello, corrected');
    expect(edited.text, 'hello, corrected');
    expect(edited.hasEditedAt(), isTrue);

    final reacted = await grace.backend.addReaction(sent.id, '👍');
    expect(reacted.reactions.single.emoji, '👍');
    expect(reacted.reactions.single.userIds, contains(grace.user.id));

    final deleted = await ada.backend.deleteMessage(sent.id);
    expect(deleted.deleted, isTrue);
    expect(deleted.text, isEmpty);
    expect(deleted.seq.toInt(), sent.seq.toInt());
  });

  test('attachments round-trip as bytes', () async {
    if (!serverUp) return;
    final client = await _newClient(baseUrl, handle('files'), 'File Sender');
    final payload = Uint8List.fromList(List<int>.generate(64, (i) => i));
    final attachment = await client.backend.uploadAttachment(
      filename: 'note.bin',
      contentType: 'application/octet-stream',
      data: payload,
    );
    expect(attachment.size.toInt(), payload.length);
    expect(attachment.isImage, isFalse);
    expect(attachment.url, startsWith('/files/'));

    // The URL the app builds carries the token and really serves the bytes.
    final url = client.backend.fileUrl(attachment.url);
    final response = await HttpClient().getUrl(Uri.parse(url)).then((r) => r.close());
    expect(response.statusCode, 200);
    final body = await response.fold<List<int>>(<int>[], (acc, chunk) => acc..addAll(chunk));
    expect(body, payload);
  });

  test('an invitation link connects two people', () async {
    if (!serverUp) return;
    final inviter = await _newClient(baseUrl, handle('inv'), 'Inviter');
    final joiner = await _newClient(baseUrl, handle('join'), 'Joiner');

    final invite = await inviter.backend.createInvite();
    expect(invite.code, isNotEmpty);
    expect(invite.url, contains('/join/${invite.code}'));
    expect(invite.valid, isTrue);

    // Preview works without a token, which is what the landing page needs.
    final anonymous = ConnectBackend(baseUrl: baseUrl);
    final preview = await anonymous.previewInvite(invite.url);
    expect(preview.valid, isTrue);
    expect(preview.inviter?.displayName, 'Inviter');

    final redeemed = await joiner.backend.redeemInvite(invite.url);
    expect(redeemed.inviter.id, inviter.user.id);
    expect(redeemed.conversation.kind, 'direct');

    // Both contact lists now contain each other.
    final inviterContacts = await inviter.backend.listContacts();
    expect(inviterContacts.map((c) => c.user.id), contains(joiner.user.id));
    final joinerContacts = await joiner.backend.listContacts();
    expect(joinerContacts.map((c) => c.user.id), contains(inviter.user.id));

    // A single-use link is spent; revoking works and is reported.
    final invites = await inviter.backend.listInvites();
    expect(invites.first.valid, isFalse);
    final extra = await inviter.backend.createInvite();
    await inviter.backend.revokeInvite(extra.code);
    final revoked = await anonymous.previewInvite(extra.code);
    expect(revoked.valid, isFalse);
    expect(revoked.reason, 'revoked');
    expect(revoked.detail, contains('cancel'));
  });

  test('an encrypted message is sealed, relayed, and opened by the peer', () async {
    if (!serverUp) return;
    final ada = await _newClient(baseUrl, handle('e2eada'), 'Ada');
    final grace = await _newClient(baseUrl, handle('e2egrace'), 'Grace');

    final conversation = await ada.backend.createDirectConversation(username: grace.user.username);
    expect(conversation.hasPeer(), isTrue);

    // Both devices publish a key; each can see the other's.
    expect(ada.crypto.ownDeviceKeyId, isNotEmpty);
    final graceKeys = await ada.backend.listDeviceKeys([grace.user.id]);
    expect(graceKeys, hasLength(1));
    expect(graceKeys.single.identityPublicKey, hasLength(32));

    // Ada prepares the conversation (which fetches Grace's device key) and
    // seals a body.
    await ada.crypto.prepareConversation(conversation);
    const secret = 'the server must never read this';
    final seal = await ada.crypto.sealMessage(
      conversation: conversation,
      content: const MessageContent(text: secret, attachments: []),
    );

    // The ciphertext must not contain the plaintext: this is the assertion the
    // whole feature rests on.
    expect(utf8.decode(seal.ciphertext, allowMalformed: true), isNot(contains(secret)));

    final sent = await ada.backend.sendEncryptedMessage(
      conversation.id,
      ciphertext: seal.ciphertext,
      nonce: seal.nonce,
      senderDeviceKeyId: seal.deviceKeyId,
      keyEpoch: seal.epoch,
      cryptoVersion: 'ratatosk/v1',
      clientMessageId: 'sealed-interop-1',
    );
    expect(sent.encrypted, isTrue);
    expect(sent.text, isEmpty, reason: 'the server must not be handed plaintext');
    expect(sent.ciphertext, equals(seal.ciphertext));

    // Grace pulls it back and opens it with the key derived from her own
    // private key and Ada's public one — no key material crossed the server.
    final page = await grace.backend.listMessages(conversation.id);
    expect(page.messages, hasLength(1));
    final stored = page.messages.single;

    // Grace renders the conversation from her own point of view, exactly as the
    // app does: `peer` is viewer-specific, the member list is not.
    final graceView = await grace.backend.getConversation(conversation.id);
    expect(graceView.peer.id, ada.user.id);
    await grace.crypto.prepareConversation(graceView);
    final opened = await grace.crypto.decryptMessage(
      conversation: graceView,
      message: stored,
      ownMessage: false,
    );
    expect(opened.ok, isTrue, reason: opened.unreadable ?? '');
    expect(opened.text, secret);

    // Their safety numbers agree, which is what a user compares out of band.
    final adaView = await ada.crypto.safetyNumberFor(graceKeys.single);
    final graceKeysOfAda = await grace.backend.listDeviceKeys([ada.user.id]);
    final graceNumber = await grace.crypto.safetyNumberFor(graceKeysOfAda.single);
    expect(adaView, equals(graceNumber));
    expect(adaView, matches(RegExp(r'^\d{5} ')));

    // A third party cannot even fetch the conversation the message lives in.
    final mallory = await _newClient(baseUrl, handle('e2emal'), 'Mallory');
    await mallory.backend.addContact(ada.user.username);
    await expectLater(
      mallory.backend.getConversation(conversation.id),
      throwsA(isA<Object>()),
      reason: 'the server must refuse a conversation the caller is not in',
    );

    // And if the ciphertext leaked, it still would not open: the key derives
    // from the pair of identities, so a conversation with the wrong peer
    // produces a different key.
    await mallory.crypto.prepareConversation(
      Conversation(
        id: conversation.id,
        kind: 'direct',
        members: [
          Member(user: ada.user),
          Member(user: mallory.user),
        ],
      ),
    );
    final stolen = await mallory.crypto.decryptMessage(
      conversation: Conversation(
        id: conversation.id,
        kind: 'direct',
        members: [
          Member(user: ada.user),
          Member(user: mallory.user),
        ],
      ),
      message: stored,
      ownMessage: false,
    );
    expect(stolen.ok, isFalse);
    expect(stolen.unreadable, isNotNull);
  });

  test('an encrypted attachment round-trips as sealed bytes', () async {
    if (!serverUp) return;
    final ada = await _newClient(baseUrl, handle('fileada'), 'Ada');
    final grace = await _newClient(baseUrl, handle('filegrace'), 'Grace');
    final conversation = await ada.backend.createDirectConversation(username: grace.user.username);
    await ada.crypto.prepareConversation(conversation);

    // A file the sender seals before it ever reaches the server.
    final plain = Uint8List.fromList(List.generate(2048, (i) => i % 256));
    final sealedFile = await ada.crypto.sealFile(plain);
    final uploaded = await ada.backend.uploadAttachment(
      filename: 'contract.pdf',
      contentType: 'application/pdf',
      data: sealedFile.ciphertext,
      encrypted: true,
    );
    // The server kept neither the name nor the type.
    expect(uploaded.encrypted, isTrue);
    expect(uploaded.filename, isEmpty);
    expect(uploaded.contentType, isEmpty);

    final seal = await ada.crypto.sealMessage(
      conversation: conversation,
      content: MessageContent(
        text: 'here it is',
        attachments: [
          EncryptedAttachment(
            blobId: uploaded.id,
            fileKey: sealedFile.key,
            nonce: sealedFile.nonce,
            filename: 'contract.pdf',
            contentType: 'application/pdf',
            size: plain.length,
          ),
        ],
      ),
    );
    await ada.backend.sendEncryptedMessage(
      conversation.id,
      ciphertext: seal.ciphertext,
      nonce: seal.nonce,
      senderDeviceKeyId: seal.deviceKeyId,
      keyEpoch: seal.epoch,
      cryptoVersion: 'ratatosk/v1',
    );

    // Grace opens the message, then the file, and gets the original bytes back.
    final graceView = await grace.backend.getConversation(conversation.id);
    await grace.crypto.prepareConversation(graceView);
    final page = await grace.backend.listMessages(conversation.id);
    final opened = await grace.crypto.decryptMessage(
      conversation: graceView,
      message: page.messages.single,
      ownMessage: false,
    );
    expect(opened.ok, isTrue);
    expect(opened.attachments.single.filename, 'contract.pdf');
    expect(opened.attachments.single.contentType, 'application/pdf');
    expect(opened.attachments.single.isImage, isFalse);

    final fetched = await grace.backend.fetchBytes('/files/${uploaded.id}');
    final decrypted = await grace.crypto.openFile(
      ciphertext: fetched,
      attachment: opened.attachments.single,
    );
    expect(decrypted, equals(plain));
  });

  test('groups, typing and a stranger is kept out', () async {
    if (!serverUp) return;
    final owner = await _newClient(baseUrl, handle('own'), 'Owner');
    final member = await _newClient(baseUrl, handle('mem'), 'Member');
    final stranger = await _newClient(baseUrl, handle('str'), 'Stranger');

    final group = await owner.backend.createGroupConversation(
      title: 'Interop Group',
      usernames: [member.user.username],
    );
    expect(group.members.length, 2);
    expect(group.members.first.role, 'owner');

    // The system note about creating the group is the first message.
    final history = await member.backend.listMessages(group.id);
    expect(history.messages.single.kind, MessageKind.MESSAGE_KIND_SYSTEM);

    // Typing indicators ride the stream.
    final events = <Event>[];
    final sub = owner.backend.subscribe().listen(events.add);
    addTearDown(() => unawaited(sub.cancel()));
    await _waitFor(events, (e) => e.hasHello(), 'owner hello');
    await member.backend.setTyping(group.id, true);
    final typing = await _waitFor(events, (e) => e.hasTyping() && e.typing.typing, 'typing');
    expect(typing.typing.displayName, 'Member');

    // Presence is visible to conversation partners.
    expect(owner.backend.baseUrl, baseUrl);

    // A stranger cannot read the group, and gets a Connect error rather than an
    // empty list.
    await expectLater(
      stranger.backend.listMessages(group.id),
      throwsA(isA<Object>()),
    );

    // The member leaves; the group survives for the owner.
    await member.backend.removeMember(group.id);
    final remaining = await owner.backend.listConversations();
    final stillThere = remaining.firstWhere((c) => c.id == group.id);
    expect(stillThere.members.map((m) => m.user.id), isNot(contains(member.user.id)));
  });
  test('a reaction added through the manager lands on the stored message', () async {
    if (!serverUp) return;
    // The seam nothing else covers: AppState.toggleReaction against the REAL
    // backend. The widget test uses the fake (whose addReaction returns the same
    // object it mutated), and the interop test above calls the backend directly
    // and never goes through the manager. So "the chip does not appear" could
    // live exactly here and no test would have caught it.
    final ada = await _newClient(baseUrl, handle('reactada'), 'Ada');
    final grace = await _newClient(baseUrl, handle('reactgrace'), 'Grace');

    final conversation =
        await ada.backend.createDirectConversation(username: grace.user.username);
    final state = AppState(
      backend: ada.backend,
      crypto: ada.crypto,
      clock: () => DateTime.now(),
    );
    await state.bootstrap(savedToken: 'unused');
    await state.openConversation(conversation.id);

    final sent = await ada.backend.sendMessage(conversation.id, text: 'react to me');
    await state.refresh();
    final entry = state.messages(conversation.id).firstWhere((m) => m.id == sent.id);
    expect(entry.message.reactions, isEmpty);

    await state.toggleReaction(conversation.id, entry.message, '👍');

    // What the bubble renders from. If the manager merged nothing, the chip has
    // nothing to draw and the user sees exactly the reported symptom.
    final after = state.messages(conversation.id).firstWhere((m) => m.id == sent.id);
    expect(after.message.reactions, isNotEmpty,
        reason: 'the manager did not merge the server\'s reaction into the thread');
    expect(after.message.reactions.single.emoji, '👍');
    expect(after.message.reactions.single.userIds, contains(ada.user.id));
  });
}

/// A signed-in client plus its user, with its own encryption identity.
typedef _Client = ({ConnectBackend backend, User user, CryptoManager crypto});

Future<_Client> _newClient(Uri baseUrl, String username, String displayName) async {
  final backend = ConnectBackend(baseUrl: baseUrl);
  final result = await backend.register(
    username: username,
    password: 'password123',
    displayName: displayName,
  );
  backend.setToken(result.token);
  // A real device: keys are generated here, registered with the server, and the
  // private halves never leave this object.
  final crypto = CryptoManager(backend: backend, storage: MemoryKeyStorage());
  await crypto.initialize(userId: result.user.id, label: 'interop', platform: 'test');
  return (backend: backend, user: result.user, crypto: crypto);
}

/// Waits for an event matching [predicate], failing the test on timeout.
Future<Event> _waitFor(
  List<Event> events,
  bool Function(Event) predicate,
  String what,
) async {
  final deadline = DateTime.now().add(const Duration(seconds: 10));
  while (DateTime.now().isBefore(deadline)) {
    for (final event in events) {
      if (predicate(event)) return event;
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
  throw TimeoutException('timed out waiting for $what (saw ${events.length} events)');
}

/// Whether anything is listening at the server's address.
Future<bool> _isReachable(Uri baseUrl) async {
  try {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 2);
    final request = await client.getUrl(baseUrl.resolve('/healthz'));
    final response = await request.close();
    await response.drain<void>();
    client.close();
    return response.statusCode == 200;
  } catch (_) {
    return false;
  }
}
