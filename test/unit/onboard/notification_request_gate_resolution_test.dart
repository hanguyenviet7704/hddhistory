import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';
import 'package:mockito/mockito.dart';

import '../../support/test_di.dart';

class _MockProfileCubit extends Mock implements ProfileCubit {}

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
  });
}
