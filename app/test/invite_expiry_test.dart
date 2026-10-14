import 'package:flutter_test/flutter_test.dart';
import 'package:ratatosk/src/ui/format.dart';

/// An invite's expiry is the opposite direction from every other timestamp in the app,
/// and rendering it through the "when did this happen" formatter is what made a list of
/// perfectly valid links look expired: a future date produced a bare time of day, so
/// "expires in a week" appeared as "9:41 PM".
void main() {
  DateTime fromNow(Duration d) => DateTime.now().add(d);

  test('a future expiry says how far away it is, not a bare time', () {
    final week = ChatFormat.expiry(fromNow(const Duration(days: 7)));
    expect(week, startsWith('expires'));
    expect(week, isNot(matches(RegExp(r'^\d{1,2}:\d{2}'))),
        reason: 'a future expiry rendered as a time of day reads as already passed');

    // The date is included once it is far enough out to be worth checking, and the
    // year only when it is not this one — "21 Oct" is checkable, "in 7 days" readable.
    expect(week, contains(RegExp(r'[A-Z][a-z]{2}')));

    // Compared against the app's own time formatter. `intl` separates the time from
    // AM/PM with a narrow no-break space, so a hand-built string differs by an
    // invisible character — the assertion would fail while looking identical.
    final tomorrow = fromNow(const Duration(days: 1));
    expect(ChatFormat.expiry(tomorrow),
        'expires tomorrow at ${ChatFormat.bubbleTime(tomorrow)}');
    expect(ChatFormat.expiry(fromNow(const Duration(hours: 3))), startsWith('expires today at '));
    expect(ChatFormat.expiry(fromNow(const Duration(minutes: 20))), startsWith('expires in '));
  });

  test('a past expiry says how long ago, and never a future tense', () {
    expect(ChatFormat.expiry(fromNow(const Duration(days: -3))), 'expired 3 days ago');
    expect(ChatFormat.expiry(fromNow(const Duration(days: -1))), 'expired yesterday');
    expect(ChatFormat.expiry(fromNow(const Duration(hours: -5))), 'expired 5 h ago');
    expect(ChatFormat.expiry(fromNow(const Duration(minutes: -5))), 'expired 5 min ago');
  });

  test('no expiry is stated rather than left blank', () {
    expect(ChatFormat.expiry(null), 'never expires');
  });
}
