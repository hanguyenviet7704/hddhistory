import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/hddhistory.dart';

void main() {
  group('resolvePaywallCountdownParts', () {
    test('Given a multi-day event, When resolving countdown parts, Then displays total hours', () {
      final parts = resolvePaywallCountdownParts(
        DateTime.utc(2026, 6, 24, 5, 6, 7),
        DateTime.utc(2026, 6, 20, 1, 2, 3),
      );

      expect(parts.hours, '100');
      expect(parts.minutes, '04');
      expect(parts.seconds, '04');
    });

    test('Given less than one day remaining, When resolving countdown parts, Then displays zero days and padded time', () {
      final parts = resolvePaywallCountdownParts(
        DateTime.utc(2026, 6, 20, 9, 5, 7),
        DateTime.utc(2026, 6, 20, 1, 2, 3),
      );

      expect(parts.hours, '08');
      expect(parts.minutes, '03');
      expect(parts.seconds, '04');
    });

    test('Given expired event, When resolving countdown parts, Then clamps to zero', () {
      final parts = resolvePaywallCountdownParts(
        DateTime.utc(2026, 6, 20, 1, 2, 3),
        DateTime.utc(2026, 6, 20, 9, 5, 7),
      );

      expect(parts.hours, '00');
      expect(parts.minutes, '00');
      expect(parts.seconds, '00');
    });
  });
}
