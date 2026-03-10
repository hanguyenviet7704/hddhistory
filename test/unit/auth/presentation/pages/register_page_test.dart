import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

void main() {
  group('buildGuestRegisterAuthEvent', () {
    test('builds anonymous guest auth event for default register flow', () {
      final event = buildGuestRegisterAuthEvent(
        forceChooseCourseAfterLogin: false,
      );

      expect(
        event,
        const AuthEvent.loginAnonymousGuest(),
      );
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
