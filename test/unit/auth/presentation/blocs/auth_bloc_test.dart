import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

void main() {
  group('resolveAuthSuccessRouteDestination', () {
    test('returns course when forceChooseCourseAfterLogin is true', () {
      final destination = resolveAuthSuccessRouteDestination(
        forceChooseCourseAfterLogin: true,
        hasCourseData: true,
      );

      expect(destination, AuthSuccessRouteDestination.course);
    });

    test('returns course when user has no course data', () {
      final destination = resolveAuthSuccessRouteDestination(
        forceChooseCourseAfterLogin: false,
        hasCourseData: false,
      );

      expect(destination, AuthSuccessRouteDestination.course);
    });

    test('returns home when override is off and user has course data', () {
      final destination = resolveAuthSuccessRouteDestination(
        forceChooseCourseAfterLogin: false,
        hasCourseData: true,
      );

      expect(destination, AuthSuccessRouteDestination.home);
    });
  });

  group('resolveRegisterGuestContinueAction', () {
    test('returns continueCurrentSession when register bootstrap already succeeded', () {
      final action = resolveRegisterGuestContinueAction(
        hasBootstrappedGuestSession: true,
      );

      expect(
        action,
        RegisterGuestContinueAction.continueCurrentSession,
      );
    });

    test('returns loginAnonymousAndNavigate when register bootstrap is unavailable', () {
      final action = resolveRegisterGuestContinueAction(
        hasBootstrappedGuestSession: false,
      );

      expect(
        action,
        RegisterGuestContinueAction.loginAnonymousAndNavigate,
      );
    });
  });

  group('resolveAuthSuccessSelectedCourseTabIndex', () {
    test('returns first tab index when course route should reset selection', () {
      final selectedTabIndex = resolveAuthSuccessSelectedCourseTabIndex(
        destination: AuthSuccessRouteDestination.course,
        resetToFirstCourseCategory: true,
      );

      expect(selectedTabIndex, 0);
    });

    test('returns null when course route should preserve the current selection', () {
      final selectedTabIndex = resolveAuthSuccessSelectedCourseTabIndex(
        destination: AuthSuccessRouteDestination.course,
        resetToFirstCourseCategory: false,
      );

      expect(selectedTabIndex, isNull);
    });

    test('returns null when destination is home', () {
      final selectedTabIndex = resolveAuthSuccessSelectedCourseTabIndex(
        destination: AuthSuccessRouteDestination.home,
        resetToFirstCourseCategory: true,
      );

      expect(selectedTabIndex, isNull);
    });
  });

  test('buildAnonymousDeviceAuthPayload only includes device info and language', () {
    final payload = buildAnonymousDeviceAuthPayload(
      deviceId: 'device-123',
      deviceName: 'Pixel 9',
      languageCode: 'en',
    );

    expect(payload.keys, unorderedEquals(['device', 'language']));
    expect(
      payload['device'],
      {
        'deviceId': 'device-123',
        'deviceName': 'Pixel 9',
      },
    );
    expect(payload['language'], 'en');
    expect(payload.containsKey('name'), isFalse);
    expect(payload.containsKey('onboarding'), isFalse);
  });
}
