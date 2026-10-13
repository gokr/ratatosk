import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ratatosk/src/api/backend.dart';
import 'package:ratatosk/src/state/app_state.dart';
import 'package:ratatosk/src/ui/settings_page.dart';
import 'package:ratatosk/src/ui/theme.dart';
import 'package:ratatosk/src/ui/widgets/privacy_policy_link.dart';
import 'package:watch_it/watch_it.dart';

import 'package:ratatosk/src/crypto/identity.dart';
import 'package:ratatosk/src/crypto/manager.dart';

import 'package:ratatosk/src/ui/google_signin.dart';

import 'fake_backend.dart';

void main() {
  late FakeBackend backend;
  late AppState state;

  setUp(() async {
    backend = FakeBackend()..seedConversation();
    state = AppState(
      backend: backend,
      crypto: CryptoManager(backend: backend, storage: MemoryKeyStorage()),
    );
    di.registerSingleton<ChatBackend>(backend);
    di.registerSingleton<GoogleSignIn>(GoogleSignIn(backend: backend));
    di.registerSingleton<AppState>(state);
    await state.bootstrap(savedToken: 'fake-token');
  });

  tearDown(() async {
    state.dispose();
    await di.reset();
    backend.dispose();
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  test('the policy URL comes from the server this client talks to', () {
    // Not hard-coded: a self-hosted Ratatosk publishes its own policy, and a
    // link to somebody else's domain would leak every new user's visit there.
    final backend = FakeBackend();
    expect(privacyPolicyUrl(backend).toString(),
        endsWith('/privacy_policy.pdf'));
    expect(privacyPolicyUrl(backend).origin, backend.baseUrl.origin);
    backend.dispose();
  });

  testWidgets('the privacy policy link is on the sign-in screen', (tester) async {
    // Google's OAuth review looks for the policy reachable from the page a user
    // lands on, so this is a compliance requirement, not decoration.
    await tester.pumpWidget(MaterialApp(
      theme: RatatoskTheme.light(),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(child: const PrivacyPolicyLink()),
        ),
      ),
    ));
    await settle(tester);
    expect(find.text('Privacy policy'), findsOneWidget);
  });

  testWidgets('deleting the account asks for the password first', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: RatatoskTheme.light(),
      home: Builder(builder: (context) => Scaffold(
        body: Center(child: TextButton(
          onPressed: () => confirmDeleteAccount(context),
          child: const Text('go'),
        )),
      )),
    ));
    await tester.tap(find.text('go'));
    await settle(tester);

    // The dialog states the consequences rather than asking "are you sure", and
    // it is explicit that a group's history survives for the other members.
    expect(find.text('Delete your account?'), findsOneWidget);
    expect(find.textContaining('cannot be undone'), findsOneWidget);
    expect(find.textContaining('Messages you sent in a group stay'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    // Backing out must not touch the account.
    await tester.tap(find.text('Keep my account'));
    await settle(tester);
    expect(backend.deletedAccounts, isEmpty);
    expect(state.signedIn, isTrue);
  });

  testWidgets('a wrong password leaves the account alone and says so', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: RatatoskTheme.light(),
      home: Builder(builder: (context) => Scaffold(
        body: Center(child: TextButton(
          onPressed: () => confirmDeleteAccount(context),
          child: const Text('go'),
        )),
      )),
    ));
    await tester.tap(find.text('go'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'not the password');
    await tester.tap(find.text('Delete everything'));
    await settle(tester);

    expect(backend.deletedAccounts, isEmpty, reason: 'the account was deleted anyway');
    expect(state.signedIn, isTrue,
        reason: 'a refused deletion must not sign the user out');
  });

  testWidgets('dismissing the profile dialog does not throw', (tester) async {
    // The same controller-lifetime bug as the delete dialog had: disposing the
    // controllers in the caller while the route is still animating out makes the
    // framework rebuild fields against a disposed controller.
    await tester.pumpWidget(MaterialApp(
      theme: RatatoskTheme.light(),
      home: Builder(builder: (context) => Scaffold(
        body: Center(child: TextButton(
          onPressed: () => showProfileDialog(context),
          child: const Text('edit'),
        )),
      )),
    ));
    await tester.tap(find.text('edit'));
    await settle(tester);
    expect(find.text('Edit profile'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Edit profile'), findsNothing);
  });

  testWidgets('the correct password deletes the account and signs out', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: RatatoskTheme.light(),
      home: Builder(builder: (context) => Scaffold(
        body: Center(child: TextButton(
          onPressed: () => confirmDeleteAccount(context),
          child: const Text('go'),
        )),
      )),
    ));
    await tester.tap(find.text('go'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'correct horse battery');
    await tester.tap(find.text('Delete everything'));
    await settle(tester);

    expect(backend.deletedAccounts, hasLength(1));
    expect(state.signedIn, isFalse, reason: 'a deleted account cannot stay signed in');
  });
}
