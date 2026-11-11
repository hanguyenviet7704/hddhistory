import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/hddhistory.dart';

void main() {
  group('shouldBootstrapRegisterGuestSession', () {
    test('returns true when register entry has no token and no bootstrap has started', () {
      final shouldBootstrap = shouldBootstrapRegisterGuestSession(
        accessToken: '',
        bootstrapFuture: null,
      );

      expect(shouldBootstrap, isTrue);
    });

    test('returns false when register bootstrap already exists', () {
      final shouldBootstrap = shouldBootstrapRegisterGuestSession(
        accessToken: '',
        bootstrapFuture: Future<bool>.value(true),
      );

      expect(shouldBootstrap, isFalse);
    });

    test('returns false when register entry already has an access token', () {
      final shouldBootstrap = shouldBootstrapRegisterGuestSession(
        accessToken: 'token',
        bootstrapFuture: null,
      );

      expect(shouldBootstrap, isFalse);
    });
  });

  group('buildGuestRegisterAuthEvent', () {
    test('builds anonymous guest auth event for default register flow', () {
      final event = buildGuestRegisterAuthEvent(
        forceChooseCourseAfterLogin: false,
        showPaywallAfterAuth: false,
      );

      expect(event, const AuthEvent.loginAnonymousGuest());
    });

    test('preserves force course chooser flag for device-recognized flow', () {
      final event = buildGuestRegisterAuthEvent(
        forceChooseCourseAfterLogin: true,
        showPaywallAfterAuth: false,
      );

      expect(
        event,
        const AuthEvent.loginAnonymousGuest(
          forceChooseCourseAfterLogin: true,
        ),
      );
    });

    test('carries first-time paywall intent for onboarding register flow', () {
      final event = buildGuestRegisterAuthEvent(
        forceChooseCourseAfterLogin: false,
        showPaywallAfterAuth: true,
      );

      expect(
        event,
        const AuthEvent.loginAnonymousGuest(
          showPaywallAfterAuth: true,
        ),
      );
    });
  });

  group('shouldBlockRegisterAuthButtons', () {
    test('does NOT block while only the silent mount-time bootstrap is running', () {
      // The bootstrap renders no spinner, so blocking on it leaves a screen that
      // looks interactive but swallows every tap — the "frozen welcome screen"
      // after reinstall. Tapping guest awaits the same bootstrap anyway.
      final blocked = shouldBlockRegisterAuthButtons(
        isBootstrapInProgress: true,
        hasActiveAuthMethod: false,
      );

      expect(blocked, isFalse);
    });

    test('blocks while an auth method is mid-flight (that button shows a spinner)', () {
      final blocked = shouldBlockRegisterAuthButtons(
        isBootstrapInProgress: false,
        hasActiveAuthMethod: true,
      );

      expect(blocked, isTrue);
    });

    test('does not block when idle', () {
      final blocked = shouldBlockRegisterAuthButtons(
        isBootstrapInProgress: false,
        hasActiveAuthMethod: false,
      );

      expect(blocked, isFalse);
    });
  });
}
