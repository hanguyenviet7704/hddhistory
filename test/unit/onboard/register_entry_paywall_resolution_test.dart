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

  group('resolveAuthenticatedSplashDestination', () {
    test('returns onboarding entry when authenticated user has not finished onboarding', () {
      final destination = resolveAuthenticatedSplashDestination(
        needsOnboarding: true,
        hasRoadmap: false,
      );

      expect(destination, SplashAuthenticatedDestination.onboardingEntry);
    });

    test('returns course when authenticated onboarded user has no roadmap', () {
      final destination = resolveAuthenticatedSplashDestination(
        needsOnboarding: false,
        hasRoadmap: false,
      );

      expect(destination, SplashAuthenticatedDestination.course);
    });

    test('returns home when authenticated onboarded user has roadmap', () {
      final destination = resolveAuthenticatedSplashDestination(
        needsOnboarding: false,
        hasRoadmap: true,
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
