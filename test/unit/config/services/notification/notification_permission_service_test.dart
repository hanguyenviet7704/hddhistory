// ignore_for_file: depend_on_referenced_packages

import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/config/services/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart' as permission_platform;

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

    test('requests a disabled state when push and local are both disabled', () async {
      final service = NotificationPermissionService(
        pushPermissionProvider: _FakePushPermissionProvider(),
        localPermissionProvider: _FakeLocalPermissionProvider(),
        isApplePlatform: true,
      );

      final state = await service.requestPermission(enablePush: false, enableLocal: false);

      expect(state.status, NotificationPermissionStatus.notDetermined);
      expect(state.canRequest, isFalse);
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

    test('requests unsupported state outside apple and android flows', () async {
      final service = NotificationPermissionService(
        pushPermissionProvider: _FakePushPermissionProvider(),
        localPermissionProvider: _FakeLocalPermissionProvider(),
        isApplePlatform: false,
        isAndroidPlatform: false,
      );

      final state = await service.requestPermission(enablePush: true, enableLocal: true);

      expect(state.status, NotificationPermissionStatus.unsupported);
      expect(state.canRequest, isFalse);
      expect(state.canOpenSettings, isTrue);
    });

    test('maps Android system permission states for status and request flows', () async {
      final service = NotificationPermissionService(
        pushPermissionProvider: _FakePushPermissionProvider(),
        localPermissionProvider: _FakeLocalPermissionProvider(),
        isApplePlatform: false,
        isAndroidPlatform: true,
        systemPermissionStatus: () async => PermissionStatus.granted,
        systemPermissionRequest: () async => PermissionStatus.denied,
      );

      final grantedState = await service.getPermissionState(enablePush: true, enableLocal: true);
      final requestedState = await service.requestPermission(enablePush: true, enableLocal: false);

      expect(grantedState.status, NotificationPermissionStatus.authorized);
      expect(grantedState.systemNotificationsEnabled, isTrue);
      expect(grantedState.localNotificationsEnabled, isTrue);
      expect(grantedState.pushNotificationsEnabled, isTrue);
      expect(requestedState.status, NotificationPermissionStatus.notDetermined);
      expect(requestedState.canRequest, isTrue);
      expect(requestedState.canOpenSettings, isTrue);
    });

    test('maps permanently denied Android permissions and delegates opening settings', () async {
      var didOpenSettings = false;
      final service = NotificationPermissionService(
        pushPermissionProvider: _FakePushPermissionProvider(),
        localPermissionProvider: _FakeLocalPermissionProvider(),
        isApplePlatform: false,
        isAndroidPlatform: true,
        systemPermissionStatus: () async => PermissionStatus.permanentlyDenied,
        openSettingsAction: () async {
          didOpenSettings = true;
        },
      );

      final state = await service.getPermissionState(enablePush: false, enableLocal: true);
      await service.openSettings();

      expect(state.status, NotificationPermissionStatus.denied);
      expect(state.canRequest, isFalse);
      expect(state.canOpenSettings, isTrue);
      expect(didOpenSettings, isTrue);
    });

    test('can be constructed with platform and callback defaults without invoking channels', () {
      expect(
        () => NotificationPermissionService(
          pushPermissionProvider: _FakePushPermissionProvider(),
          localPermissionProvider: _FakeLocalPermissionProvider(),
        ),
        returnsNormally,
      );
    });

    test('uses default permission handler platform bindings when callbacks are not injected', () async {
      final originalPlatform = permission_platform.PermissionHandlerPlatform.instance;
      final fakePlatform = _FakePermissionHandlerPlatform(
        statusResult: PermissionStatus.granted,
        requestResult: PermissionStatus.permanentlyDenied,
      );
      permission_platform.PermissionHandlerPlatform.instance = fakePlatform;
      addTearDown(() {
        permission_platform.PermissionHandlerPlatform.instance = originalPlatform;
      });

      final service = NotificationPermissionService(
        pushPermissionProvider: _FakePushPermissionProvider(),
        localPermissionProvider: _FakeLocalPermissionProvider(),
        isApplePlatform: false,
        isAndroidPlatform: true,
      );

      final currentState = await service.getPermissionState(enablePush: true, enableLocal: true);
      final requestedState = await service.requestPermission(enablePush: true, enableLocal: true);
      await service.openSettings();

      expect(currentState.status, NotificationPermissionStatus.authorized);
      expect(requestedState.status, NotificationPermissionStatus.denied);
      expect(fakePlatform.statusChecks, 1);
      expect(fakePlatform.requestCalls, 1);
      expect(fakePlatform.openSettingsCalls, 1);
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

class _FakePermissionHandlerPlatform extends permission_platform.PermissionHandlerPlatform {
  _FakePermissionHandlerPlatform({
    required this.statusResult,
    required this.requestResult,
  });

  final PermissionStatus statusResult;
  final PermissionStatus requestResult;
  int statusChecks = 0;
  int requestCalls = 0;
  int openSettingsCalls = 0;

  @override
  Future<PermissionStatus> checkPermissionStatus(Permission permission) async {
    statusChecks += 1;
    return statusResult;
  }

  @override
  Future<ServiceStatus> checkServiceStatus(Permission permission) async => ServiceStatus.enabled;

  @override
  Future<bool> openAppSettings() async {
    openSettingsCalls += 1;
    return true;
  }

  @override
  Future<Map<Permission, PermissionStatus>> requestPermissions(List<Permission> permissions) async {
    requestCalls += 1;
    return <Permission, PermissionStatus>{
      for (final permission in permissions) permission: requestResult,
    };
  }

  @override
  Future<bool> shouldShowRequestPermissionRationale(Permission permission) async => false;
}
