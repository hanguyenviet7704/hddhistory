import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

void main() {
  group('shouldShowRegisterPaywallAfterAuth', () {
    test('returns true for recognized-device first-time handoff', () {
      final shouldShow = shouldShowRegisterPaywallAfterAuth(
        hasRecognizedDevice: true,
        hasPendingFirstTimePaywallAfterAuth: false,
      );

      expect(shouldShow, isTrue);
    });

    test('returns true when a first-time paywall intent is pending after restart', () {
      final shouldShow = shouldShowRegisterPaywallAfterAuth(
        hasRecognizedDevice: false,
        hasPendingFirstTimePaywallAfterAuth: true,
      );

      expect(shouldShow, isTrue);
    });

    test('returns false for regular unauthenticated register entry', () {
      final shouldShow = shouldShowRegisterPaywallAfterAuth(
        hasRecognizedDevice: false,
        hasPendingFirstTimePaywallAfterAuth: false,
      );

      expect(shouldShow, isFalse);
    });
  });
}
