import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/hddhistory.dart';

void main() {
  group('StreakDay', () {
    test('resolves to local midnight, not UTC midnight', () {
      final day = StreakDay.resolve(DateTime(2026, 7, 31, 0, 13));

      expect(day, DateTime(2026, 7, 31));
      expect(day.hour, 0);
      expect(day.minute, 0);
      expect(day.isUtc, isFalse);
    });

    test('files an instant by the device calendar, whatever its UTC date is', () {
      // The bug this replaces: keying by UTC day put a small-hours session in
      // Vietnam on the previous day, because 00:13 local is still 17:13 UTC the
      // day before. The local calendar day is the one the week strip draws.
      final instant = DateTime(2026, 7, 31, 0, 13);
      final expected = DateTime(
        instant.toLocal().year,
        instant.toLocal().month,
        instant.toLocal().day,
      );

      expect(StreakDay.resolve(instant), expected);
      expect(StreakDay.resolve(instant.toUtc()), expected);
    });

    test('treats two instants in the same local day as the same day', () {
      expect(
        StreakDay.isSame(DateTime(2026, 7, 31, 0, 13), DateTime(2026, 7, 31, 23, 47)),
        isTrue,
      );
      expect(
        StreakDay.isSame(DateTime(2026, 7, 31, 23, 59), DateTime(2026, 8, 1, 0, 1)),
        isFalse,
      );
    });

    test('never reports a match when either side is missing', () {
      expect(StreakDay.isSame(null, DateTime(2026, 7, 31)), isFalse);
      expect(StreakDay.isSame(DateTime(2026, 7, 31), null), isFalse);
      expect(StreakDay.isSame(null, null), isFalse);
    });

    test('zero-pads the local-store key so it sorts and compares as text', () {
      expect(StreakDay.key(DateTime(2026, 7, 31, 8, 17)), '2026-07-31');
      expect(StreakDay.key(DateTime(2026, 12, 5)), '2026-12-05');
      expect(StreakDay.key(DateTime(2026, 1, 1)), '2026-01-01');
    });

    test('today() agrees with resolving the current instant', () {
      expect(StreakDay.today(), StreakDay.resolve(DateTime.now()));
    });
  });
}
