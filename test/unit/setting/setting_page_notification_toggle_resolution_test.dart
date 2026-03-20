import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

void main() {
  group('SettingPage notification toggle resolution', () {
    test(
      'Given iOS, When resolving toggle action, Then the page uses system settings',
      () {
        final action = resolveSettingNotificationToggleAction(
          platform: TargetPlatform.iOS,
          state: const NotificationState(
            hasLoadedPermissionState: true,
            permissionStatus: NotificationPermissionStatus.authorized,
            canRequestPermission: false,
          ),
          value: false,
        );

        expect(action, SettingNotificationToggleAction.openSystemSettings);
      },
    );

    test(
      'Given Android, When resolving toggle action, Then the page keeps the in-app toggle path',
      () {
        final action = resolveSettingNotificationToggleAction(
          platform: TargetPlatform.android,
          state: const NotificationState(
            hasLoadedPermissionState: true,
            permissionStatus: NotificationPermissionStatus.authorized,
            canRequestPermission: false,
          ),
          value: false,
        );

        expect(action, SettingNotificationToggleAction.toggleInAppPreference);
      },
    );

    test(
      'Given iOS and requestable permission, When enabling from settings, Then the page keeps the in-app request flow',
      () {
        final action = resolveSettingNotificationToggleAction(
          platform: TargetPlatform.iOS,
          state: const NotificationState(
            hasLoadedPermissionState: true,
            permissionStatus: NotificationPermissionStatus.notDetermined,
            canRequestPermission: true,
          ),
          value: true,
        );

        expect(action, SettingNotificationToggleAction.toggleInAppPreference);
      },
    );

    test(
      'Given iOS and non-requestable permission, When enabling from settings, Then the page opens system settings',
      () {
        final action = resolveSettingNotificationToggleAction(
          platform: TargetPlatform.iOS,
          state: const NotificationState(
            hasLoadedPermissionState: true,
            permissionStatus: NotificationPermissionStatus.denied,
            canRequestPermission: false,
            canOpenSettings: true,
          ),
          value: true,
        );

        expect(action, SettingNotificationToggleAction.openSystemSettings);
      },
    );

    test(
      'Given iOS and disabled system permission, When disabling from settings, Then the page keeps the in-app preference path',
      () {
        final action = resolveSettingNotificationToggleAction(
          platform: TargetPlatform.iOS,
          state: const NotificationState(
            hasLoadedPermissionState: true,
            permissionStatus: NotificationPermissionStatus.denied,
            canRequestPermission: false,
            canOpenSettings: true,
          ),
          value: false,
        );

        expect(action, SettingNotificationToggleAction.toggleInAppPreference);
      },
    );

    test(
      'Given iOS and an unloaded permission state, When resolving toggle action, Then the page keeps the in-app path until runtime state is refreshed',
      () {
        final action = resolveSettingNotificationToggleAction(
          platform: TargetPlatform.iOS,
          state: const NotificationState(
            permissionStatus: NotificationPermissionStatus.denied,
            canRequestPermission: false,
            canOpenSettings: true,
          ),
          value: true,
        );

        expect(action, SettingNotificationToggleAction.toggleInAppPreference);
      },
    );

    test(
      'Given no pending settings roundtrip, When resolving refresh behavior, Then refresh preserves the existing app preference',
      () {
        final request = resolveSettingNotificationRefreshRequest(
          hasPendingSystemSettingsSync: false,
        );

        expect(request.syncAuthorizedPreference, isTrue);
        expect(request.syncPreferenceToPermissionState, isFalse);
      },
    );

    test(
      'Given a pending settings roundtrip, When resolving refresh behavior, Then the next resume adopts the live system permission state',
      () {
        final request = resolveSettingNotificationRefreshRequest(
          hasPendingSystemSettingsSync: true,
        );

        expect(request.syncAuthorizedPreference, isFalse);
        expect(request.syncPreferenceToPermissionState, isTrue);
      },
    );
  });
}
