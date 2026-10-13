import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ratatosk/src/session_store.dart';
import 'package:ratatosk/src/ui/language.dart';
import 'package:ratatosk/src/ui/format.dart';

void main() {
  testWidgets('Swedish labels resolve, unknown labels retain English', (tester) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('sv'),
      supportedLocales: const [Locale('en'), Locale('sv')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Builder(builder: (context) => Column(children: [
        Text(tr(context, 'Settings')),
        Text(tr(context, 'Sign in')),
        Text(tr(context, 'Unknown label')),
      ])),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Inställningar'), findsOneWidget);
    expect(find.text('Logga in'), findsOneWidget);
    expect(find.text('Unknown label'), findsOneWidget);
  });
  test('language preference persists', () async {
    SharedPreferences.setMockInitialValues({});
    await SessionStore().writeLanguage('sv');
    expect(await SessionStore().readLanguage(), 'sv');
    await SessionStore().writeLanguage(null);
    expect(await SessionStore().readLanguage(), isNull);
  });
  test('Swedish day labels and system time format', () async {
    await initializeDateFormatting('sv');
    final previous = Intl.defaultLocale;
    Intl.defaultLocale = 'sv';
    try {
      expect(ChatFormat.dayLabel(DateTime.now()), 'Idag');
      expect(ChatFormat.bubbleTime(DateTime(2026, 1, 1, 23, 7)), '23:07');
    } finally {
      Intl.defaultLocale = previous;
    }
  });
}
