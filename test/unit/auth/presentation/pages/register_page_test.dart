import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

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
      );

      expect(event, const AuthEvent.loginAnonymousGuest());
    });

    test('preserves force course chooser flag for device-recognized flow', () {
      final event = buildGuestRegisterAuthEvent(
        forceChooseCourseAfterLogin: true,
      );

      expect(
        event,
        const AuthEvent.loginAnonymousGuest(
          forceChooseCourseAfterLogin: true,
        ),
      );
    });
  });
}
