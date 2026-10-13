import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ratatosk/src/api/backend.dart';
import 'package:ratatosk/src/crypto/identity.dart';
import 'package:ratatosk/src/crypto/manager.dart';
import 'package:ratatosk/src/link_controller.dart';
import 'package:ratatosk/src/state/app_state.dart';
import 'package:ratatosk/src/ui/google_signin.dart';
import 'package:ratatosk/src/ui/google_signup_screen.dart';
import 'package:ratatosk/src/ui/language.dart';
import 'package:ratatosk/src/ui/signin_methods.dart';
import 'package:ratatosk/src/ui/theme.dart';
import 'package:watch_it/watch_it.dart';

import 'fake_backend.dart';

/// The Google flow's client half.
///
/// Two things are worth testing without a browser: that the callback parameters are
/// read and then taken *out* of the URL — a pending token left in the address bar is
/// a token sitting in the history and a reload that looks like a failure — and that
/// the sign-up screen refuses to submit without an invitation, because that is the
/// rule the product asked for.
void main() {
  late FakeBackend backend;
  late AppState state;
  late LinkController links;

  setUp(() async {
    backend = FakeBackend()..seedConversation();
    state = AppState(backend: backend, crypto: CryptoManager(backend: backend, storage: MemoryKeyStorage()));
    links = LinkController();
    di.registerSingleton<ChatBackend>(backend);
    di.registerSingleton<AppState>(state);
    di.registerSingleton<LinkController>(links);
  });

  tearDown(() async {
    state.dispose();
    await di.reset();
    backend.dispose();
  });

  test('a callback is read, and the URL no longer carries the token', () {
    final callback = Uri.parse(
        'https://chat.example/?google_pending=pt-123&google_suggested_username=gokr&google_email=a%40b.se');
    final result = readGoogleCallback(callback);
    expect(result.pendingToken, 'pt-123');
    expect(result.suggestedUsername, 'gokr');
    expect(result.email, 'a@b.se');
    expect(result.hasPending, isTrue);

    final cleaned = stripGoogleParams(callback);
    expect(cleaned, isNot(contains('google_pending')));
    expect(cleaned, isNot(contains('pt-123')));
    // Anything unrelated in the URL survives: an invite code must not be lost.
    final withInvite = Uri.parse(
        'https://chat.example/?invite=abc&google_token=tok');
    final cleanedInvite = stripGoogleParams(withInvite);
    expect(cleanedInvite, contains('invite=abc'));
    expect(cleanedInvite, isNot(contains('tok')));
  });

  test('a session from the callback signs in without a password', () async {
    final result = readGoogleCallback(Uri.parse('https://x/?google_token=tok-1'));
    state.handleGoogleResult(result);
    // _adoptToken is async; let it settle.
    for (var i = 0; i < 20; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(backend.token, 'tok-1');
    expect(state.signedIn, isTrue, reason: 'the session from Google was not adopted');
    expect(state.googleResult, isNull);
  });

  test('an error from the callback is surfaced, not swallowed', () async {
    state.handleGoogleResult(readGoogleCallback(
        Uri.parse('https://x/?google_error=Sign-in+was+cancelled.')));
    expect(state.googleResult?.hasError, isTrue);
    expect(state.googleResult?.error, 'Sign-in was cancelled.');
    state.leaveGoogleFlow();
    expect(state.googleResult, isNull);
  });

  testWidgets('sign-up requires an invitation before it submits', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: RatatoskTheme.light(),
      home: GoogleSignUpScreen(
        result: const GoogleCallbackResult(
            pendingToken: 'pt-1', suggestedUsername: 'gokr', email: 'goran@example.com'),
      ),
    ));
    await tester.pumpAndSettle();

    // The suggestion is offered and editable, not imposed.
    expect(find.text('gokr'), findsOneWidget);
    expect(find.textContaining('Invitation'), findsWidgets);

    // Username present but no code: refused locally, and nothing reached the server.
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    expect(backend.finishedGoogleSignUps, isEmpty,
        reason: 'an account was attempted without an invitation');

    // With a code it goes through, trimmed. The case is left alone: the server
    // normalizes invite codes itself, and mangling them here would be a second,
    // divergent rule about what a code is.
    await tester.enterText(find.byType(TextField).at(2), '  ABC123  ');
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    expect(backend.finishedGoogleSignUps.single, 'pt-1|gokr|ABC123');
  });

  testWidgets('an invitation from a link is used without asking', (tester) async {
    links.submitCode('fromlink');
    await tester.pumpWidget(MaterialApp(
      theme: RatatoskTheme.light(),
      home: GoogleSignUpScreen(
        result: const GoogleCallbackResult(pendingToken: 'pt-2', suggestedUsername: 'ada'),
      ),
    ));
    await tester.pumpAndSettle();
    // The field is already filled, so submitting needs no further input.
    expect(find.text('fromlink'), findsOneWidget);
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    expect(backend.finishedGoogleSignUps.single, 'pt-2|ada|fromlink');
  });

  testWidgets('the Google button is hidden when the server has no client id',
      (tester) async {
    backend.googleEnabled = false;
    final google = GoogleSignIn(backend: backend);
    await google.load();
    expect(google.available, isFalse,
        reason: 'a server without a client id must not offer the button');

    backend.googleEnabled = true;
    final enabled = GoogleSignIn(backend: backend);
    await enabled.load();
    expect(enabled.available, isTrue);
    expect(enabled.config!.authorizationEndpoint,
        'https://example.test/auth/google/start');
  });

  testWidgets('an account with a password is offered Google as a second way in',
      (tester) async {
    // The exact situation reported: an account made with a password, where signing in
    // with Google cannot help because nobody had linked the identity. Connecting it is
    // a distinct action, and this is where it lives.
    backend.signInMethodsResponse = const SignInMethods(methods: ['password']);
    await tester.pumpWidget(MaterialApp(
      theme: RatatoskTheme.light(),
      home: Scaffold(body: SingleChildScrollView(child: SignInMethodsSection())),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Connect Google'), findsOneWidget);
    expect(find.text('Disconnect Google'), findsNothing);
    expect(find.textContaining('second way in'), findsOneWidget);
  });

  testWidgets('a Google-only account shows it is the only way in', (tester) async {
    backend.signInMethodsResponse =
        const SignInMethods(methods: ['google'], googleEmail: 'goran@example.com');
    await tester.pumpWidget(MaterialApp(
      theme: RatatoskTheme.light(),
      home: Scaffold(body: SingleChildScrollView(child: SignInMethodsSection())),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Disconnect Google'), findsOneWidget);
    expect(find.textContaining('only way'), findsOneWidget);
    // The connected address is shown, which is how somebody confirms *which* Google
    // account is attached.
    expect(find.textContaining('goran@example.com'), findsOneWidget);
  });

  testWidgets('Swedish translations cover the Google screens', (tester) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('sv'),
      supportedLocales: const [Locale('en'), Locale('sv')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Builder(builder: (context) => Text(tr(context, 'Sign in with Google'))),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Logga in med Google'), findsOneWidget);
  });
}

