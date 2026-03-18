import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

void main() {
  group('SettingPage notification toggle resolution', () {
    test(
      'Given iOS, When resolving toggle action, Then the page uses system settings',
      () {
        final action = resolveSettingNotificationToggleAction(
          platform: TargetPlatform.iOS,
        );

        expect(action, SettingNotificationToggleAction.openSystemSettings);
      },
    );

    test(
      'Given Android, When resolving toggle action, Then the page keeps the in-app toggle path',
      () {
        final action = resolveSettingNotificationToggleAction(
          platform: TargetPlatform.android,
        );

        expect(action, SettingNotificationToggleAction.toggleInAppPreference);
      },
    );

    test(
      'Given iOS, When resolving refresh behavior, Then the page adopts the live system permission state',
      () {
        final request = resolveSettingNotificationRefreshRequest(
          toggleAction: SettingNotificationToggleAction.openSystemSettings,
        );

        expect(request.syncAuthorizedPreference, isFalse);
        expect(request.syncPreferenceToPermissionState, isTrue);
      },
    );

    test(
      'Given Android, When resolving refresh behavior, Then refresh still preserves the in-app preference semantics',
      () {
        final request = resolveSettingNotificationRefreshRequest(
          toggleAction: SettingNotificationToggleAction.toggleInAppPreference,
        );

        expect(request.syncAuthorizedPreference, isTrue);
        expect(request.syncPreferenceToPermissionState, isFalse);
      },
    );
  });
}
