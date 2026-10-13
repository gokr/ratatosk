import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ratatosk/src/session_store.dart';
import 'package:ratatosk/src/ui/format.dart';

void main() {
  test('12/24 hour selection handles midnight and noon', () {
    expect(ChatFormat.bubbleTime(DateTime(2026, 1, 1), use24Hour: true), '00:00');
    expect(ChatFormat.bubbleTime(DateTime(2026, 1, 1), use24Hour: false), '12:00 AM');
    expect(ChatFormat.bubbleTime(DateTime(2026, 1, 1, 12), use24Hour: false), '12:00 PM');
    expect(ChatFormat.bubbleTime(DateTime(2026, 1, 1, 23, 7), use24Hour: true), '23:07');
    expect(ChatFormat.bubbleTime(DateTime(2026, 1, 1, 23, 7), use24Hour: false), '11:07 PM');
  });
  test('clock choice persists and system default removes override', () async {
    SharedPreferences.setMockInitialValues({});
    final store = SessionStore();
    expect(await store.readClockFormat(), isNull);
    await store.writeClockFormat(true);
    expect(await SessionStore().readClockFormat(), isTrue);
    await store.writeClockFormat(false);
    expect(await store.readClockFormat(), isFalse);
    await store.writeClockFormat(null);
    expect(await store.readClockFormat(), isNull);
  });
}
