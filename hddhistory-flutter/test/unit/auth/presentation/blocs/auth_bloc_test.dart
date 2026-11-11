import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/hddhistory.dart';

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

  group('resolveCourseEntryBootstrapResult', () {
    test('returns retryable failure for ordinary network and server failures', () {
      expect(
        resolveCourseEntryBootstrapResult(const AppException.connection()),
        CourseEntryBootstrapResult.retryableFailure,
      );
      expect(
        resolveCourseEntryBootstrapResult(const AppException.server()),
        CourseEntryBootstrapResult.retryableFailure,
      );
    });

    test('returns unrecoverable failure for auth rejection failures', () {
      expect(
        resolveCourseEntryBootstrapResult(const AppException.unauthorized()),
        CourseEntryBootstrapResult.unrecoverableFailure,
      );
      expect(
        resolveCourseEntryBootstrapResult(const AppException.forbidden()),
        CourseEntryBootstrapResult.unrecoverableFailure,
      );
      expect(
        resolveCourseEntryBootstrapResult(const AppException.invalidInput()),
        CourseEntryBootstrapResult.unrecoverableFailure,
      );
    });

    test('returns retryable failure when anonymous auth fails without a classified exception', () {
      expect(
        resolveCourseEntryBootstrapResult(null),
        CourseEntryBootstrapResult.retryableFailure,
      );
    });
  });

  group('isCourseEntryDataReady', () {
    final homeReady = HomeState.initial().copyWith(
      status: HomeStatus.success,
      pageData: const BasePageBreak<CategoryEntity>(
        items: [
          CategoryEntity(
            id: 'category-1',
            courses: [CourseEntity(id: 'course-1')],
          ),
        ],
      ),
    );
    final progressReady = ProgressState.initial().copyWith(status: ProgressStatus.success);
    final profileReady = ProfileState.initial().copyWith(status: ProfileStatus.success);

    test('returns true when course catalog is loaded and dependent states have no failures', () {
      expect(
        isCourseEntryDataReady(
          homeState: homeReady,
          progressState: progressReady,
          profileState: profileReady,
        ),
        isTrue,
      );
    });

    test('returns false when home catalog loading failed', () {
      expect(
        isCourseEntryDataReady(
          homeState: HomeState.initial().copyWith(status: HomeStatus.failure),
          progressState: progressReady,
          profileState: profileReady,
        ),
        isFalse,
      );
    });

    test('returns false when home catalog succeeds without any courses', () {
      expect(
        isCourseEntryDataReady(
          homeState: HomeState.initial().copyWith(status: HomeStatus.success),
          progressState: progressReady,
          profileState: profileReady,
        ),
        isFalse,
      );
    });

    test('returns false when progress or profile dependency reports failure', () {
      expect(
        isCourseEntryDataReady(
          homeState: homeReady,
          progressState: ProgressState.initial().copyWith(status: ProgressStatus.failure),
          profileState: profileReady,
        ),
        isFalse,
      );
      expect(
        isCourseEntryDataReady(
          homeState: homeReady,
          progressState: progressReady,
          profileState: ProfileState.initial().copyWith(status: ProfileStatus.failure),
        ),
        isFalse,
      );
    });
  });
}
