import 'package:flutter_test/flutter_test.dart';
import 'package:meup/config/services/notification/notification_core_config.dart';
import 'package:meup/config/services/notification/permissions/notification_permission_service.dart';

void main() {
  group('NotificationPermissionService', () {
    test('returns a disabled state when push and local are both disabled', () async {
      final service = NotificationPermissionService(
        pushPermissionProvider: _FakePushPermissionProvider(),
        localPermissionProvider: _FakeLocalPermissionProvider(),
        isApplePlatform: true,
      );

      final state = await service.getPermissionState(enablePush: false, enableLocal: false);

      expect(state.status, NotificationPermissionStatus.notDetermined);
      expect(state.systemNotificationsEnabled, isFalse);
      expect(state.localNotificationsEnabled, isFalse);
      expect(state.pushNotificationsEnabled, isFalse);
      expect(state.canOpenSettings, isFalse);
    });

    test('uses push authorization for apple push plus local permission state', () async {
      final service = NotificationPermissionService(
        pushPermissionProvider: _FakePushPermissionProvider(
          status: NotificationPermissionStatus.authorized,
        ),
        localPermissionProvider: _FakeLocalPermissionProvider(),
        isApplePlatform: true,
      );

      final state = await service.getPermissionState(enablePush: true, enableLocal: true);

      expect(state.status, NotificationPermissionStatus.authorized);
      expect(state.systemNotificationsEnabled, isTrue);
      expect(state.localNotificationsEnabled, isTrue);
      expect(state.pushNotificationsEnabled, isTrue);
    });

    test('requests local permission when only local notifications are enabled on apple', () async {
      final localProvider = _FakeLocalPermissionProvider(requestResult: true);
      final service = NotificationPermissionService(
        pushPermissionProvider: _FakePushPermissionProvider(),
        localPermissionProvider: localProvider,
        isApplePlatform: true,
      );

      final state = await service.requestPermission(enablePush: false, enableLocal: true);

      expect(state.status, NotificationPermissionStatus.authorized);
      expect(state.localNotificationsEnabled, isTrue);
      expect(localProvider.requestCalls, 1);
    });

    test('returns unsupported state outside apple and android flows', () async {
      final service = NotificationPermissionService(
        pushPermissionProvider: _FakePushPermissionProvider(),
        localPermissionProvider: _FakeLocalPermissionProvider(),
        isApplePlatform: false,
        isAndroidPlatform: false,
      );

      final state = await service.getPermissionState(enablePush: true, enableLocal: true);

      expect(state.status, NotificationPermissionStatus.unsupported);
      expect(state.canRequest, isFalse);
      expect(state.canOpenSettings, isTrue);
    });
  });
}

class _FakePushPermissionProvider implements NotificationPushPermissionProvider {
  _FakePushPermissionProvider({
    this.status = NotificationPermissionStatus.notDetermined,
  });

  final NotificationPermissionStatus status;

  @override
  Future<NotificationPermissionStatus> getPermissionStatus() async => status;

  @override
  Future<NotificationPermissionStatus> requestPermission() async => NotificationPermissionStatus.authorized;
}

class _FakeLocalPermissionProvider implements NotificationLocalPermissionProvider {
  _FakeLocalPermissionProvider({
    this.requestResult = false,
  });

  final bool requestResult;
  int requestCalls = 0;

  @override
  Future<bool> isPermissionGranted() async => false;

  @override
  Future<bool> requestPermission() async {
    requestCalls += 1;
    return requestResult;
  }
}
