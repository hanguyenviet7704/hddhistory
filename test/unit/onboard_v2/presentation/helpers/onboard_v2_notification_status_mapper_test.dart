import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/hddhistory.dart';

void main() {
  group('OnboardV2NotificationStatusMapper', () {
    test('maps authorized and provisional pre-request states to already authorized', () {
      expect(
        OnboardV2NotificationStatusMapper.fromCurrentState(
          const NotificationState(
            hasLoadedPermissionState: true,
            permissionStatus: NotificationPermissionStatus.authorized,
          ),
        ),
        OnboardV2NotificationStatus.alreadyAuthorized,
      );

      expect(
        OnboardV2NotificationStatusMapper.fromCurrentState(
          const NotificationState(
            hasLoadedPermissionState: true,
            permissionStatus: NotificationPermissionStatus.provisional,
          ),
        ),
        OnboardV2NotificationStatus.alreadyAuthorized,
      );
    });

    test('maps unsupported capability to unsupported', () {
      expect(
        OnboardV2NotificationStatusMapper.fromCurrentState(
          const NotificationState(
            hasLoadedPermissionState: true,
            permissionStatus: NotificationPermissionStatus.unsupported,
          ),
        ),
        OnboardV2NotificationStatus.unsupported,
      );
    });

    test('maps denied state that can open settings to permanently denied', () {
      expect(
        OnboardV2NotificationStatusMapper.fromCurrentState(
          const NotificationState(
            hasLoadedPermissionState: true,
            permissionStatus: NotificationPermissionStatus.denied,
            canOpenSettings: true,
          ),
        ),
        OnboardV2NotificationStatus.permanentlyDenied,
      );
    });

    test('maps denied state without settings ownership to already denied', () {
      expect(
        OnboardV2NotificationStatusMapper.fromCurrentState(
          const NotificationState(
            hasLoadedPermissionState: true,
            permissionStatus: NotificationPermissionStatus.denied,
            canOpenSettings: false,
          ),
        ),
        OnboardV2NotificationStatus.alreadyDenied,
      );
    });

    test('maps request result authorization and denial distinctly', () {
      expect(
        OnboardV2NotificationStatusMapper.fromRequestResult(
          const NotificationState(permissionStatus: NotificationPermissionStatus.authorized),
        ),
        OnboardV2NotificationStatus.authorized,
      );
      expect(
        OnboardV2NotificationStatusMapper.fromRequestResult(
          const NotificationState(permissionStatus: NotificationPermissionStatus.denied),
        ),
        OnboardV2NotificationStatus.denied,
      );
    });

    test('maps maybe later explicitly', () {
      expect(OnboardV2NotificationStatusMapper.maybeLater(), OnboardV2NotificationStatus.maybeLater);
    });
  });
}
