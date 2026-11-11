import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/hddhistory.dart';
import 'package:mockito/mockito.dart';

import '../../support/test_di.dart';

class _MockProfileCubit extends Mock implements ProfileCubit {
  @override
  Future<void> loadUser({bool isInit = false}) async {}
}

class _FakeDailyWarmUpLocalDataSource implements DailyWarmUpLocalDataSource {
  final Map<String, String> onboardingCompletedDates = {};

  @override
  Future<void> cacheDailyWarmUp(DailyWarmUpModel model) async {}

  @override
  Future<void> clearCache() async {}

  @override
  Future<DailyWarmUpModel?> getCachedDailyWarmUp() async => null;

  @override
  Future<String> getOnboardingCompletedDate(String userId) async => onboardingCompletedDates[userId] ?? '';

  @override
  Future<String> getShownDate(String userId) async => '';

  @override
  Future<void> markOnboardingCompletedDateIfAbsent(String userId, String date) async {
    onboardingCompletedDates.putIfAbsent(userId, () => date);
  }

  @override
  Future<void> markShownDate(String userId, String date) async {}
}

void main() {
  group('Notification gate resolution', () {
    test('Given authorized permission state, When onboarding gate resolution runs, Then the gate still shows until the first-time gate is completed', () {
      const state = NotificationState(
        hasLoadedPermissionState: true,
        permissionStatus: NotificationPermissionStatus.authorized,
        systemNotificationsEnabled: true,
        localNotificationsEnabled: true,
        pushNotificationsEnabled: true,
      );

      expect(state.isPermissionGranted, isTrue);
      expect(state.shouldSkipOnboardingGate, isFalse);
    });

    test('Given capability-unavailable state, When onboarding gate resolution runs, Then the gate is skipped', () {
      const state = NotificationState(
        hasLoadedPermissionState: true,
        permissionStatus: NotificationPermissionStatus.unsupported,
      );

      expect(state.isCapabilityUnavailable, isTrue);
      expect(state.shouldSkipOnboardingGate, isTrue);
    });

    test('Given requestable permission state, When onboarding gate resolution runs, Then the gate still shows', () {
      const state = NotificationState(
        hasLoadedPermissionState: true,
        permissionStatus: NotificationPermissionStatus.notDetermined,
        canRequestPermission: true,
      );

      expect(state.shouldSkipOnboardingGate, isFalse);
    });

    test('Given the first-time gate is already completed, When gate helper runs, Then the notification page is skipped even if permission is already granted', () {
      const state = NotificationState(
        hasLoadedPermissionState: true,
        permissionStatus: NotificationPermissionStatus.authorized,
        systemNotificationsEnabled: true,
        localNotificationsEnabled: true,
        pushNotificationsEnabled: true,
      );

      expect(
        shouldSkipNotificationRequestGate(
          hasCompletedFirstTimeNotificationGate: true,
          notificationState: state,
        ),
        isTrue,
      );
    });

    test('Given course-entry mode before CTA, When legacy notification gate is complete, Then the course-entry gate is not skipped', () {
      const state = NotificationState(
        hasLoadedPermissionState: true,
        permissionStatus: NotificationPermissionStatus.authorized,
        systemNotificationsEnabled: true,
        localNotificationsEnabled: true,
        pushNotificationsEnabled: true,
      );

      expect(
        shouldSkipNotificationRequestGate(
          hasCompletedFirstTimeNotificationGate: true,
          hasCompletedCourseEntryNotificationGate: false,
          courseEntryMode: true,
          notificationState: state,
        ),
        isFalse,
      );
    });

    test('Given course-entry mode before CTA, When notifications are unsupported, Then the user still sees the course-entry gate', () {
      const state = NotificationState(
        hasLoadedPermissionState: true,
        permissionStatus: NotificationPermissionStatus.unsupported,
      );

      expect(
        shouldSkipNotificationRequestGate(
          hasCompletedFirstTimeNotificationGate: false,
          hasCompletedCourseEntryNotificationGate: false,
          courseEntryMode: true,
          notificationState: state,
        ),
        isFalse,
      );
    });

    test('Given course-entry CTA was completed, When course-entry gate helper runs, Then the notification page can continue', () {
      const state = NotificationState(
        hasLoadedPermissionState: true,
        permissionStatus: NotificationPermissionStatus.notDetermined,
        canRequestPermission: true,
      );

      expect(
        shouldSkipNotificationRequestGate(
          hasCompletedFirstTimeNotificationGate: false,
          hasCompletedCourseEntryNotificationGate: true,
          courseEntryMode: true,
          notificationState: state,
        ),
        isTrue,
      );
    });
  });

  group('UserCubit notification gate persistence', () {
    late _MockProfileCubit profileCubit;

    setUp(() async {
      await setupLocaleCubitForTests();
      profileCubit = _MockProfileCubit();
      AppDI.injector.registerSingleton<ProfileCubit>(profileCubit);
    });

    tearDown(() async {
      await resetInjectorForTests();
    });

    test('Given the first-time notification gate is completed, When clearData runs, Then the completion flag persists', () async {
      final cubit = UserCubit(NoOpTrackingService());
      addTearDown(cubit.close);

      cubit.completeFirstTimeNotificationGate();
      await cubit.clearData();

      expect(cubit.state.hasCompletedFirstTimeNotificationGate, isTrue);
      verify(profileCubit.reset()).called(1);
    });

    test('Given course-entry notification gate is completed, When clearData runs, Then course-entry completion persists without paywall intent', () async {
      final cubit = UserCubit(NoOpTrackingService());
      addTearDown(cubit.close);

      cubit.completeCourseEntryNotificationGate();
      await cubit.clearData();

      expect(cubit.state.hasCompletedCourseEntryNotificationGate, isTrue);
      expect(cubit.state.hasPendingFirstTimePaywallAfterAuth, isFalse);
      verify(profileCubit.reset()).called(1);
    });

    test('Given only legacy notification gate is completed, When state updates, Then course-entry completion remains independent', () {
      final cubit = UserCubit(NoOpTrackingService());
      addTearDown(cubit.close);

      cubit.completeFirstTimeNotificationGate();

      expect(cubit.state.hasCompletedFirstTimeNotificationGate, isTrue);
      expect(cubit.state.hasCompletedCourseEntryNotificationGate, isFalse);
      expect(cubit.state.hasPendingFirstTimePaywallAfterAuth, isFalse);
    });

    test('Given recognized-device flow receives auth later, When auth is set, Then daily warm-up onboarding date is persisted', () async {
      final localDataSource = _FakeDailyWarmUpLocalDataSource();
      AppDI.injector.registerSingleton<DailyWarmUpLocalDataSource>(localDataSource);
      final cubit = UserCubit(NoOpTrackingService());
      addTearDown(cubit.close);

      cubit.startFirstTimeRegisterFlow();
      cubit.setAuth(const AuthEntity(user: UserEntity(id: 'user-1')));
      await pumpEventQueue();

      expect(localDataSource.onboardingCompletedDates['user-1'], matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
    });
  });
}
