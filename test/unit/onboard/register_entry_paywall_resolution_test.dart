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

  group('shouldSkipOnboardingByRemoteConfig', () {
    test('returns true when onboarding config is disabled', () {
      final shouldSkip = shouldSkipOnboardingByRemoteConfig(
        const OnboardingConfigEntity(enable: false),
      );

      expect(shouldSkip, isTrue);
    });

    test('returns false when onboarding config is enabled', () {
      final shouldSkip = shouldSkipOnboardingByRemoteConfig(
        const OnboardingConfigEntity(enable: true),
      );

      expect(shouldSkip, isFalse);
    });
  });

  group('resolveUnauthenticatedSplashEntryDestination', () {
    test('returns course-entry notification when onboarding is disabled', () {
      final destination = resolveUnauthenticatedSplashEntryDestination(
        needsOnboarding: true,
        onboardingDisabled: true,
        hasRecognizedDevice: false,
      );

      expect(destination, SplashUnauthenticatedDestination.courseEntryNotification);
    });

    test('returns course-entry notification when onboarding is disabled even for recognized devices', () {
      final destination = resolveUnauthenticatedSplashEntryDestination(
        needsOnboarding: true,
        onboardingDisabled: true,
        hasRecognizedDevice: true,
      );

      expect(destination, SplashUnauthenticatedDestination.courseEntryNotification);
    });

    test('returns legacy register notification when onboarding is enabled and the device is recognized', () {
      final destination = resolveUnauthenticatedSplashEntryDestination(
        needsOnboarding: true,
        onboardingDisabled: false,
        hasRecognizedDevice: true,
      );

      expect(destination, SplashUnauthenticatedDestination.legacyRegisterNotification);
    });
  });

  group('resolveAuthenticatedSplashDestination', () {
    test('returns onboarding entry when authenticated user has not finished onboarding', () {
      final destination = resolveAuthenticatedSplashDestination(
        needsOnboarding: true,
      );

      expect(destination, SplashAuthenticatedDestination.onboardingEntry);
    });

    /// Home even with no course to jump back into. The roadmap used to decide
    /// this and sent every guest to the Explore grid on every launch, because a
    /// guest never has a roadmap (product call, 2026-08-13).
    test('returns home for an onboarded user, roadmap or not', () {
      final destination = resolveAuthenticatedSplashDestination(
        needsOnboarding: false,
      );

      expect(destination, SplashAuthenticatedDestination.home);
    });
  });

  group('shouldInitializeAuthenticatedHomeData', () {
    test('returns false without access token', () {
      expect(
        shouldInitializeAuthenticatedHomeData(
          accessToken: '',
          needsOnboarding: false,
        ),
        isFalse,
      );
    });

    test('returns false when token exists but onboarding is unfinished', () {
      expect(
        shouldInitializeAuthenticatedHomeData(
          accessToken: 'token',
          needsOnboarding: true,
        ),
        isFalse,
      );
    });

    test('returns true when token exists and onboarding is finished', () {
      expect(
        shouldInitializeAuthenticatedHomeData(
          accessToken: 'token',
          needsOnboarding: false,
        ),
        isTrue,
      );
    });
  });
}
