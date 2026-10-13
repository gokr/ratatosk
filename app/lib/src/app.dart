import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import 'state/app_state.dart';
import 'ui/auth_screen.dart';
import 'ui/google_signup_screen.dart';
import 'ui/home_shell.dart';
import 'ui/theme.dart';
import 'ui/widgets/brand_logo.dart';

/// The two themes, exported so `main.dart` does not have to reach into the
/// theme file's internals.
final ThemeData lightTheme = RatatoskTheme.light();
final ThemeData darkTheme = RatatoskTheme.dark();

/// Decides what the app shows: the splash while the stored session is checked,
/// the sign-in screen when there is no session, the shell when there is one.
class AppGate extends WatchingWidget {
  const AppGate({super.key});

  @override
  Widget build(BuildContext context) {
    final state = watchIt<AppState>();
    if (state.bootstrapping) {
      return const _Splash();
    }
    // A Google round-trip that needs finishing takes over the whole screen: it is a
    // step in signing in, not a place to browse away from.
    final google = state.googleResult;
    if (google != null && !state.signedIn) {
      if (google.hasPending) {
        return GoogleSignUpScreen(result: google);
      }
      if (google.hasError) {
        return GoogleErrorScreen(message: google.error!);
      }
      state.leaveGoogleFlow();
    }
    if (!state.signedIn) {
      return const AuthScreen();
    }
    return const HomeShell();
  }
}
class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            BrandLogo(size: 72),
            SizedBox(height: 24),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
      ),
    );
  }
}
