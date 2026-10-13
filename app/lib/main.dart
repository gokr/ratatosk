import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:watch_it/watch_it.dart';

import 'src/api/backend.dart';
import 'src/api/connect_backend.dart';
import 'src/crypto/manager.dart';
import 'src/crypto/secure_storage.dart';
import 'src/ui/widgets/encrypted_image.dart';
import 'src/app.dart';
import 'src/link_controller.dart';
import 'src/session_store.dart';
import 'src/state/app_state.dart';

/// Wire the app: one instance of each piece, registered with get_it, so any
/// widget can reach the state with `watchIt<AppState>()` / `di<AppState>()`.
///
/// The backend is built before the state because the state is handed it, and
/// both are registered before the first frame so no widget ever sees a
/// half-built graph.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('sv');

  final session = SessionStore();
  final storedBaseUrl = await session.readBaseUrl();
  final baseUrl = storedBaseUrl ?? SessionStore.defaultBaseUrl();

  final backend = ConnectBackend(baseUrl: baseUrl);

  // The private keys live in the platform keystore; on the web there is no
  // keystore, so a sealed browser-storage implementation is used instead (see
  // SecureKeyStorage, which falls back when the platform cannot provide one).
  final crypto = CryptoManager(backend: backend, storage: SecureKeyStorage());
  final state = AppState(backend: backend, crypto: crypto);
  state.setClockFormat(await session.readClockFormat());
  state.setLanguage(await session.readLanguage());
  final links = LinkController();

  di.registerSingleton<SessionStore>(session);
  di.registerSingleton<ChatBackend>(backend);
  di.registerSingleton<CryptoManager>(crypto);
  di.registerSingleton<AttachmentCache>(AttachmentCache());
  di.registerSingleton<AppState>(state);
  di.registerSingleton<LinkController>(links);

  runApp(const RatatoskApp());

  // Startup work happens after the first frame so the splash is on screen while
  // the token is checked: a slow or unreachable server must not look like a
  // frozen app.
  await links.start();
  await state.bootstrap(
    savedToken: await session.readToken(),
    onToken: session.writeToken,
  );
}

/// The app's root widget: theme, sign-in gate and the shell.
class RatatoskApp extends WatchingWidget {
  const RatatoskApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = watchIt<AppState>();
    final language = state.language ??
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    Intl.defaultLocale = language == 'sv' ? 'sv' : 'en';
    return MaterialApp(
      title: 'Ratatosk',
      locale: state.language == null ? null : Locale(state.language!),
      supportedLocales: const [Locale('en'), Locale('sv')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      home: const AppGate(),
      // The shell owns its own navigation; a global key lets the invite flow
      // jump back to the conversation list after redeeming.
      navigatorKey: navigatorKey,
      builder: (context, child) {
        // Show server errors once, wherever they surface.
        final error = state.lastError;
        if (error != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (navigatorKey.currentContext == null) return;
            ScaffoldMessenger.maybeOf(navigatorKey.currentContext!)
                ?.showSnackBar(SnackBar(content: Text(error)));
            state.clearError();
          });
        }
        return child ?? const SizedBox.shrink();
      },
    );
  }
}

/// A global navigator key, so non-widget code (the invite flow, deep links) can
/// navigate without a BuildContext.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
