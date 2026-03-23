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

  group('shouldBypassFirstTimeUserPaywallForPremium', () {
    test('returns true when premium user hits onboarding paywall after auth', () {
      final shouldBypass = shouldBypassFirstTimeUserPaywallForPremium(
        forceChooseCourseAfterLogin: false,
        showPaywallAfterAuth: true,
        isPremium: true,
      );

      expect(shouldBypass, isTrue);
    });

    test('returns true when pending first-time paywall intent meets premium user', () {
      final shouldBypass = shouldBypassFirstTimeUserPaywallForPremium(
        forceChooseCourseAfterLogin: false,
        showPaywallAfterAuth: false,
        hasPendingFirstTimePaywallAfterAuth: true,
        isPremium: true,
      );

      expect(shouldBypass, isTrue);
    });

    test('returns false when user is not premium', () {
      final shouldBypass = shouldBypassFirstTimeUserPaywallForPremium(
        forceChooseCourseAfterLogin: false,
        showPaywallAfterAuth: true,
        isPremium: false,
      );

      expect(shouldBypass, isFalse);
    });

    test('returns false when premium user has no first-time paywall intent', () {
      final shouldBypass = shouldBypassFirstTimeUserPaywallForPremium(
        forceChooseCourseAfterLogin: false,
        showPaywallAfterAuth: false,
        hasPendingFirstTimePaywallAfterAuth: false,
        isPremium: true,
      );

      expect(shouldBypass, isFalse);
    });

    test('returns false when course-selection override suppresses paywall flow', () {
      final shouldBypass = shouldBypassFirstTimeUserPaywallForPremium(
        forceChooseCourseAfterLogin: true,
        showPaywallAfterAuth: true,
        hasPendingFirstTimePaywallAfterAuth: true,
        isPremium: true,
      );

      expect(shouldBypass, isFalse);
    });
  });
}
