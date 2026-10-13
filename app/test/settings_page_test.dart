import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ratatosk/src/api/backend.dart';
import 'package:ratatosk/src/crypto/identity.dart';
import 'package:ratatosk/src/crypto/manager.dart';
import 'package:ratatosk/src/session_store.dart';
import 'package:ratatosk/src/state/app_state.dart';
import 'package:ratatosk/src/ui/google_signin.dart';
import 'package:ratatosk/src/ui/settings_page.dart';
import 'package:ratatosk/src/ui/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watch_it/watch_it.dart';

import 'fake_backend.dart';

void main() {
  testWidgets('the settings screen builds', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final backend = FakeBackend()..seedConversation();
    final state = AppState(
      backend: backend,
      crypto: CryptoManager(backend: backend, storage: MemoryKeyStorage()),
    );
    di.registerSingleton<ChatBackend>(backend);
    di.registerSingleton<AppState>(state);
    di.registerSingleton<SessionStore>(SessionStore());
    di.registerSingleton<GoogleSignIn>(GoogleSignIn(backend: backend));
    await state.bootstrap(savedToken: 'fake-token');

    await tester.pumpWidget(MaterialApp(
      theme: RatatoskTheme.light(),
      home: const SettingsPage(),
    ));
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(tester.takeException(), isNull, reason: 'the settings screen threw');
    expect(find.text('Settings'), findsOneWidget);

    state.dispose();
    await di.reset();
    backend.dispose();
  });
}
