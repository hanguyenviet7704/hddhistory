import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

void main() {
  group('shouldForceRegisterNavigationAfterReset', () {
    test('does NOT re-navigate when already on the register screen', () {
      // Re-going to RegisterRoute from the register screen REPLACES it with a
      // fresh instance whose mount-time guest bootstrap restarts. A 401 storm
      // re-fires this every couple of seconds, so the welcome screen remounts
      // forever and never becomes interactive.
      final shouldNavigate = shouldForceRegisterNavigationAfterReset(RouteNamed.register);

      expect(shouldNavigate, isFalse);
    });

    test('does not re-navigate from the splash screen (splash owns its routing)', () {
      expect(shouldForceRegisterNavigationAfterReset(RouteNamed.splash), isFalse);
    });

    test('does not re-navigate during onboarding', () {
      expect(shouldForceRegisterNavigationAfterReset(RouteNamed.onboardV2), isFalse);
    });

    test('does not re-navigate when the current route is unknown', () {
      expect(shouldForceRegisterNavigationAfterReset(''), isFalse);
    });

    test('DOES navigate when the session dies on an authenticated screen', () {
      expect(shouldForceRegisterNavigationAfterReset(RouteNamed.home), isTrue);
    });
  });
}
