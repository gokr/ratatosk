// Two devices of one account, against a running server.
//
// The bug this pins down: a group message sent from one of your devices was
// unreadable on your other devices, forever, because the sender-key distribution
// skipped every device belonging to our own user. Run it against a live server:
//
//   dart run tool/two_devices.dart http://127.0.0.1:8080
//
// ignore_for_file: avoid_print
import 'dart:io';


import 'package:ratatosk/src/api/connect_backend.dart';
import 'package:ratatosk/src/crypto/identity.dart';
import 'package:ratatosk/src/crypto/message_content.dart';
import 'package:ratatosk/src/crypto/session.dart';

Future<void> main(List<String> args) async {
  final base = Uri.parse(args.isEmpty ? 'http://127.0.0.1:8080' : args.first);
  final stamp = DateTime.now().millisecondsSinceEpoch;
  final adaName = 'ada$stamp';
  final peerName = 'peer$stamp';
  const password = 'correct horse battery';

  // The peer only has to exist: a group needs another member, and the point of
  // the test is the two devices of *one* account.
  final peerBackend = ConnectBackend(baseUrl: base);
  await peerBackend.register(username: peerName, password: password, displayName: 'Peer');
  print('registered $peerName');

  // --- device A ---------------------------------------------------------
  final aBackend = ConnectBackend(baseUrl: base);
  final aAuth = await aBackend.register(
    username: adaName,
    password: password,
    displayName: 'Ada',
  );
  // The device key registers over an authenticated call, so sign in first.
  aBackend.setToken(aAuth.token);
  final aStore = MemoryKeyStorage();
  final aIdentity = IdentityManager(backend: aBackend, storage: aStore);
  final deviceA = await aIdentity.ensureIdentity(label: 'Linux desktop', platform: 'linux');
  aBackend.setDeviceKeyId(deviceA.deviceKeyId);
  print('device A: ${deviceA.deviceKeyId}');

  final group = await aBackend.createGroupConversation(title: 'Devices', usernames: [peerName]);
  print('group ${group.id} with ${group.members.length} member(s)');

  final sessionA = CryptoSession(backend: aBackend, identity: deviceA)
    ..ownUserId = aAuth.user.id;

  // --- device B: same account, its own device key -----------------------
  final bBackend = ConnectBackend(baseUrl: base);
  final bAuth = await bBackend.login(username: adaName, password: password);
  bBackend.setToken(bAuth.token);
  final bStore = MemoryKeyStorage();
  final bIdentity = IdentityManager(backend: bBackend, storage: bStore);
  final deviceB = await bIdentity.ensureIdentity(label: 'Phone', platform: 'android');
  bBackend.setDeviceKeyId(deviceB.deviceKeyId);
  print('device B: ${deviceB.deviceKeyId}');

  if (deviceA.deviceKeyId == deviceB.deviceKeyId) {
    stderr.writeln('FAIL: both devices share a device key id');
    exit(1);
  }
  final sessionB = CryptoSession(backend: bBackend, identity: deviceB)
    ..ownUserId = bAuth.user.id;

  final members = group.members.map((m) => m.user.id).toList();

  // --- A sends a sealed group message ----------------------------------
  await sessionA.refreshDeviceKeys(members);
  await sessionA.distributeSenderKey(conversationId: group.id, memberUserIds: members);
  final sealed = await sessionA.encrypt(
    conversationId: group.id,
    content: MessageContent(text: 'sent from device A'),
    isGroup: true,
  );
  final stored = await aBackend.sendEncryptedMessage(
    group.id,
    ciphertext: sealed.sealed.combined,
    nonce: sealed.sealed.nonce,
    senderDeviceKeyId: deviceA.deviceKeyId,
    keyEpoch: sealed.epoch,
    cryptoVersion: 'ratatosk/v1',
    clientMessageId: 'two-devices-$stamp',
  );
  print('A sent seq=${stored.seq} as ${stored.senderDeviceKeyId}');

  // --- B must be able to read it ---------------------------------------
  final envelopes = await bBackend.listKeyEnvelopes(conversationId: group.id);
  print('envelopes on the server: ${envelopes.length} '
      '(${envelopes.map((e) => '${e.senderDeviceKeyId}->${e.recipientDeviceKeyId}').join(', ')})');

  await sessionB.refreshDeviceKeys(members);
  final learned = await sessionB.collectSenderKeys(conversationId: group.id);
  print('B collected $learned sender key(s)');

  final opened = await sessionB.decrypt(
    conversationId: group.id,
    senderDeviceKeyId: stored.senderDeviceKeyId,
    ciphertext: stored.ciphertext,
    nonce: stored.nonce,
    isGroup: true,
    peer: null,
    ownMessage: true,
  );

  var failures = 0;
  if (!opened.ok) {
    stderr.writeln('FAIL: B cannot read A\'s message: ${opened.failure}');
    failures++;
  } else if (opened.content!.text != 'sent from device A') {
    stderr.writeln('FAIL: B read the wrong text: ${opened.content!.text}');
    failures++;
  } else {
    print('B read it: "${opened.content!.text}"');
  }

  // A must still be able to read its own message (own sender key, restored from
  // its own store: the restart path).
  final ownRead = await sessionA.decrypt(
    conversationId: group.id,
    senderDeviceKeyId: deviceA.deviceKeyId,
    ciphertext: stored.ciphertext,
    nonce: stored.nonce,
    isGroup: true,
    peer: null,
    ownMessage: true,
  );
  if (!ownRead.ok) {
    stderr.writeln('FAIL: A cannot read its own message: ${ownRead.failure}');
    failures++;
  } else {
    print('A read its own message');
  }

  // A third device joining later: it must be given the key by A's next
  // distribution, with no rotation.
  final cBackend = ConnectBackend(baseUrl: base);
  final cAuth = await cBackend.login(username: adaName, password: password);
  cBackend.setToken(cAuth.token);
  final cStore = MemoryKeyStorage();
  final cIdentity = IdentityManager(backend: cBackend, storage: cStore);
  final deviceC = await cIdentity.ensureIdentity(label: 'Tablet', platform: 'ios');
  cBackend.setDeviceKeyId(deviceC.deviceKeyId);
  print('device C (later): ${deviceC.deviceKeyId}');

  final sessionC = CryptoSession(backend: cBackend, identity: deviceC)
    ..ownUserId = cAuth.user.id;
  await sessionC.refreshDeviceKeys(members);
  await sessionC.distributeSenderKey(conversationId: group.id, memberUserIds: members);
  // A prepares again, which is what should notice the newcomer.
  await sessionA.refreshDeviceKeys(members);
  await sessionA.distributeSenderKey(conversationId: group.id, memberUserIds: members);

  await sessionC.refreshDeviceKeys(members);
  final cLearned = await sessionC.collectSenderKeys(conversationId: group.id);
  final cOpened = await sessionC.decrypt(
    conversationId: group.id,
    senderDeviceKeyId: stored.senderDeviceKeyId,
    ciphertext: stored.ciphertext,
    nonce: stored.nonce,
    isGroup: true,
    peer: null,
    ownMessage: true,
  );
  if (!cOpened.ok) {
    stderr.writeln('FAIL: device C (registered later) cannot read A\'s message '
        '($cLearned key(s) collected): ${cOpened.failure}');
    failures++;
  } else {
    print('C (registered later) read it too');
  }

  // The server never sees a sender key in the clear: the stored envelope is not
  // the key itself.
  final all = await aBackend.listKeyEnvelopes(conversationId: group.id);
  for (final envelope in all) {
    final key = sessionA.ownSenderKey(group.id).key;
    if (envelope.wrappedKey.length == key.length &&
        List.generate(key.length, (i) => envelope.wrappedKey[i] == key[i])
            .every((equal) => equal)) {
      stderr.writeln('FAIL: an envelope holds the raw sender key');
      failures++;
    }
  }

  print(failures == 0 ? 'TWO-DEVICE TEST PASSED' : 'TWO-DEVICE TEST FAILED ($failures)');
  exit(failures == 0 ? 0 : 1);
}
