import 'package:flutter_test/flutter_test.dart';
import 'package:meup/src/learning_import/learning_import.dart';

/// The number the premium ticket popup promises ("Your 5 tickets reset in N
/// days"), so the rounding rules are the behavior under test: always UP, never
/// below one.
void main() {
  group('importTicketResetInDays', () {
    test('rounds a partial day up', () {
      // 26 hours away is "in 2 days" to a person, not "in 1".
      expect(
        importTicketResetInDays(DateTime.now().add(const Duration(hours: 26))),
        2,
      );
    });

    test('a reset within the day is still "in 1 day"', () {
      expect(
        importTicketResetInDays(DateTime.now().add(const Duration(hours: 5))),
        1,
      );
    });

    test('never says zero, even for a reset already past', () {
      expect(
        importTicketResetInDays(
          DateTime.now().subtract(const Duration(hours: 3)),
        ),
        1,
      );
    });

    test('a clean three days out says three', () {
      expect(
        importTicketResetInDays(
          DateTime.now().add(const Duration(days: 3, minutes: -30)),
        ),
        3,
      );
    });
  });
}
