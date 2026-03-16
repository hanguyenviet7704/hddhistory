import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

void main() {
  group('shouldOpenFirstTimeUserPaywall', () {
    test('returns true when onboarding flow opts into paywall after auth', () {
      final shouldOpen = shouldOpenFirstTimeUserPaywall(
        forceChooseCourseAfterLogin: false,
        showPaywallAfterAuth: true,
      );

      expect(shouldOpen, isTrue);
    });

    test('returns false when recognized-device course flow is active', () {
      final shouldOpen = shouldOpenFirstTimeUserPaywall(
        forceChooseCourseAfterLogin: true,
        showPaywallAfterAuth: true,
        hasPendingFirstTimePaywallAfterAuth: true,
      );

      expect(shouldOpen, isFalse);
    });

    test('returns false when register caller does not opt into paywall', () {
      final shouldOpen = shouldOpenFirstTimeUserPaywall(
        forceChooseCourseAfterLogin: false,
        showPaywallAfterAuth: false,
      );

      expect(shouldOpen, isFalse);
    });

    test('returns true when persisted first-time paywall intent survives register re-entry', () {
      final shouldOpen = shouldOpenFirstTimeUserPaywall(
        forceChooseCourseAfterLogin: false,
        showPaywallAfterAuth: false,
        hasPendingFirstTimePaywallAfterAuth: true,
      );

      expect(shouldOpen, isTrue);
    });
  });
}
