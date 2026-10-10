import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import 'state/app_state.dart';
import 'ui/auth_screen.dart';
import 'ui/home_shell.dart';
import 'ui/theme.dart';

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
            _Logo(size: 72),
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

/// The app mark: a chat bubble with a small tail, drawn rather than shipped as
/// an asset so there is no image to keep in sync with the palette.
class _Logo extends StatelessWidget {
  const _Logo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(Icons.forum_rounded, color: Colors.white, size: size * 0.55),
    );
  }
}
