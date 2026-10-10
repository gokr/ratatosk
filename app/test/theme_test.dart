import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ratatosk/src/ui/theme.dart';

void main() {
  testWidgets('the theme exposes the chat colours', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: RatatoskTheme.light(),
        home: Builder(
          builder: (context) {
            final colors = RatatoskTheme.of(context);
            // The own-message bubble is the app's identity colour; if this
            // drifts, every bubble in the app changes colour.
            expect(colors.ownBubble, RatatoskTheme.seed);
            expect(colors.ownText, Colors.white);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  });
}
