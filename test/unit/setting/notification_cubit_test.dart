import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

import '../../support/test_di.dart';

void main() {
  group('NotificationCubit', () {
    late NotificationService? originalService;
    late bool lastPersistedPreference;

    setUp(() async {
      await setupLocaleCubitForTests();
      originalService = NotificationService.debugInstance;
      lastPersistedPreference = true;
      debugConfigureNotificationPreferenceStore(
        readAction: () async => lastPersistedPreference,
        writeAction: (enabled) async {
          lastPersistedPreference = enabled;
        },
      );
    });

    tearDown(() async {
      if (originalService == null) {
        NotificationService.debugResetInstance();
      } else {
        NotificationService.debugSetInstance(originalService!);
      }
      debugConfigureNotificationPreferenceStore();
      await resetInjectorForTests();
    });

    test('Given authorized permission on refresh, When syncAuthorizedPreference is true, Then the app preference is initialized on', () async {
      final permissionService = _RecordingPermissionService(
        getStateResult: const NotificationPermissionState(
          status: NotificationPermissionStatus.authorized,
          systemNotificationsEnabled: true,
          localNotificationsEnabled: true,
          pushNotificationsEnabled: true,
          canRequest: false,
        ),
        requestStateResult: const NotificationPermissionState(
          status: NotificationPermissionStatus.authorized,
          systemNotificationsEnabled: true,
          localNotificationsEnabled: true,
          pushNotificationsEnabled: true,
          canRequest: false,
        ),
      );
      final localNotifications = _FakeLocalNotifications();
      _installDebugNotificationService(
        permissionService: permissionService,
        localNotifications: localNotifications,
      );
      final cubit = NotificationCubit();
      addTearDown(cubit.close);

      await cubit.refreshPermissionState(syncAuthorizedPreference: true);

      expect(cubit.state.hasInitializedPreference, isTrue);
      expect(cubit.state.notificationsEnabled, isTrue);
      expect(cubit.state.isEffectivelyEnabled, isTrue);
      expect(lastPersistedPreference, isTrue);
      expect(permissionService.getPermissionStateCalls, 1);
    });

    test('Given requestable permission state, When onboarding enable runs, Then permission is requested and the preference turns on after grant', () async {
      final permissionService = _RecordingPermissionService(
        getStateResult: const NotificationPermissionState(
          status: NotificationPermissionStatus.notDetermined,
          systemNotificationsEnabled: false,
          localNotificationsEnabled: false,
          pushNotificationsEnabled: false,
          canRequest: true,
        ),
        requestStateResult: const NotificationPermissionState(
          status: NotificationPermissionStatus.authorized,
          systemNotificationsEnabled: true,
          localNotificationsEnabled: true,
          pushNotificationsEnabled: true,
          canRequest: false,
        ),
      );
      _installDebugNotificationService(
        permissionService: permissionService,
        localNotifications: _FakeLocalNotifications(),
      );
      final cubit = NotificationCubit();
      addTearDown(cubit.close);

      await cubit.enableFromOnboardingGate();

      expect(cubit.state.permissionStatus, NotificationPermissionStatus.authorized);
      expect(cubit.state.notificationsEnabled, isTrue);
      expect(cubit.state.hasInitializedPreference, isTrue);
      expect(lastPersistedPreference, isTrue);
      expect(permissionService.requestPermissionCalls, 1);
      expect(permissionService.openSettingsCalls, 0);
    });

    test('Given enabled notifications, When disabling the app preference from settings, Then local reminders are cancelled and effective state turns off', () async {
      final permissionService = _RecordingPermissionService(
        getStateResult: const NotificationPermissionState(
          status: NotificationPermissionStatus.authorized,
          systemNotificationsEnabled: true,
          localNotificationsEnabled: true,
          pushNotificationsEnabled: true,
          canRequest: false,
        ),
        requestStateResult: const NotificationPermissionState(
          status: NotificationPermissionStatus.authorized,
          systemNotificationsEnabled: true,
          localNotificationsEnabled: true,
          pushNotificationsEnabled: true,
          canRequest: false,
        ),
      );
      final localNotifications = _FakeLocalNotifications();
      _installDebugNotificationService(
        permissionService: permissionService,
        localNotifications: localNotifications,
      );
      final cubit = NotificationCubit();
      addTearDown(cubit.close);

      await cubit.refreshPermissionState(syncAuthorizedPreference: true);
      await cubit.disableAppPreference();

      expect(cubit.state.notificationsEnabled, isFalse);
      expect(cubit.state.isEffectivelyEnabled, isFalse);
      expect(cubit.state.hasInitializedPreference, isTrue);
      expect(lastPersistedPreference, isFalse);
      expect(localNotifications.cancelAllCalls, 1);
      expect(localNotifications.cancelAllSchedulesCalls, 1);
    });

    test('Given iOS settings flow returns with authorized permission, When syncing preference to permission state, Then the app preference turns on', () async {
      final permissionService = _RecordingPermissionService(
        getStateResult: const NotificationPermissionState(
          status: NotificationPermissionStatus.denied,
          systemNotificationsEnabled: false,
          localNotificationsEnabled: false,
          pushNotificationsEnabled: false,
          canRequest: false,
          canOpenSettings: true,
        ),
        requestStateResult: const NotificationPermissionState(
          status: NotificationPermissionStatus.authorized,
          systemNotificationsEnabled: true,
          localNotificationsEnabled: true,
          pushNotificationsEnabled: true,
          canRequest: false,
        ),
      );
      _installDebugNotificationService(
        permissionService: permissionService,
        localNotifications: _FakeLocalNotifications(),
      );
      final cubit = NotificationCubit();
      addTearDown(cubit.close);

      await cubit.disableAppPreference();
      permissionService.getStateResult = const NotificationPermissionState(
        status: NotificationPermissionStatus.authorized,
        systemNotificationsEnabled: true,
        localNotificationsEnabled: true,
        pushNotificationsEnabled: true,
        canRequest: false,
      );

      await cubit.refreshPermissionState(syncPreferenceToPermissionState: true);

      expect(cubit.state.notificationsEnabled, isTrue);
      expect(cubit.state.isEffectivelyEnabled, isTrue);
      expect(cubit.state.hasInitializedPreference, isTrue);
      expect(lastPersistedPreference, isTrue);
    });

    test('Given iOS settings flow returns with denied permission, When syncing preference to permission state, Then the app preference turns off', () async {
      final permissionService = _RecordingPermissionService(
        getStateResult: const NotificationPermissionState(
          status: NotificationPermissionStatus.authorized,
          systemNotificationsEnabled: true,
          localNotificationsEnabled: true,
          pushNotificationsEnabled: true,
          canRequest: false,
        ),
        requestStateResult: const NotificationPermissionState(
          status: NotificationPermissionStatus.authorized,
          systemNotificationsEnabled: true,
          localNotificationsEnabled: true,
          pushNotificationsEnabled: true,
          canRequest: false,
        ),
      );
      _installDebugNotificationService(
        permissionService: permissionService,
        localNotifications: _FakeLocalNotifications(),
      );
      final cubit = NotificationCubit();
      addTearDown(cubit.close);

      await cubit.refreshPermissionState(syncAuthorizedPreference: true);
      permissionService.getStateResult = const NotificationPermissionState(
        status: NotificationPermissionStatus.denied,
        systemNotificationsEnabled: false,
        localNotificationsEnabled: false,
        pushNotificationsEnabled: false,
        canRequest: false,
        canOpenSettings: true,
      );

      await cubit.refreshPermissionState(syncPreferenceToPermissionState: true);

      expect(cubit.state.notificationsEnabled, isFalse);
      expect(cubit.state.isEffectivelyEnabled, isFalse);
      expect(cubit.state.hasInitializedPreference, isTrue);
      expect(lastPersistedPreference, isFalse);
    });

    test('Given settings toggle opens system settings on iOS, When opening from settings, Then the app settings deep link is triggered', () async {
      final permissionService = _RecordingPermissionService(
        getStateResult: const NotificationPermissionState(
          status: NotificationPermissionStatus.authorized,
          systemNotificationsEnabled: true,
          localNotificationsEnabled: true,
          pushNotificationsEnabled: true,
          canRequest: false,
          canOpenSettings: true,
        ),
        requestStateResult: const NotificationPermissionState(
          status: NotificationPermissionStatus.authorized,
          systemNotificationsEnabled: true,
          localNotificationsEnabled: true,
          pushNotificationsEnabled: true,
          canRequest: false,
        ),
      );
      _installDebugNotificationService(
        permissionService: permissionService,
        localNotifications: _FakeLocalNotifications(),
      );
      final cubit = NotificationCubit();
      addTearDown(cubit.close);

      await cubit.openSettingsFromSettings();

      expect(permissionService.openSettingsCalls, 1);
      expect(permissionService.requestPermissionCalls, 0);
    });
  });
}

void _installDebugNotificationService({
  required _RecordingPermissionService permissionService,
  required _FakeLocalNotifications localNotifications,
}) {
  NotificationService.debugSetInstance(
    NotificationService(
      pushTransport: _FakePushTransport(),
      localNotifications: localNotifications,
      permissionService: permissionService,
    ),
  );
}

class _FakePushTransport implements NotificationPushTransport {
  final StreamController<TransportRemoteMessage> _foregroundController = StreamController<TransportRemoteMessage>.broadcast(sync: true);
  final StreamController<TransportRemoteMessage> _openedController = StreamController<TransportRemoteMessage>.broadcast(sync: true);
  final StreamController<String> _tokenController = StreamController<String>.broadcast(sync: true);

  @override
  Future<void> configureForegroundPresentation() async {}

  @override
  Stream<TransportRemoteMessage> get foregroundMessages => _foregroundController.stream;

  @override
  Future<TransportRemoteMessage?> getInitialMessage() async => null;

  @override
  Future<NotificationPermissionStatus> getPermissionStatus() async => NotificationPermissionStatus.authorized;

  @override
  Future<String?> getToken() async => null;

  @override
  Stream<TransportRemoteMessage> get openedMessages => _openedController.stream;

  @override
  Future<void> registerBackgroundHandler() async {}

  @override
  Future<NotificationPermissionStatus> requestPermission() async => NotificationPermissionStatus.authorized;

  @override
  Stream<String> get tokenRefreshStream => _tokenController.stream;
}

class _FakeLocalNotifications implements NotificationLocalNotifications {
  final StreamController<TransportLocalAction> _controller = StreamController<TransportLocalAction>.broadcast(sync: true);

  int cancelAllCalls = 0;
  int cancelAllSchedulesCalls = 0;

  @override
  Stream<TransportLocalAction> get actionStream => _controller.stream;

  @override
  Future<void> cancel(int id) async {}

  @override
  Future<void> cancelAll() async => cancelAllCalls += 1;

  @override
  Future<void> cancelAllSchedules() async => cancelAllSchedulesCalls += 1;

  @override
  Future<void> cancelSchedule(int id) async {}

  @override
  Future<void> dispose() => _controller.close();

  @override
  Future<TransportLocalAction?> getInitialAction() async => null;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> isPermissionGranted() async => true;

  @override
  Future<void> registerListeners() async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> schedule(NotificationScheduleRequest request) async {}

  @override
  Future<void> show(NotificationRequest request) async {}
}

class _RecordingPermissionService extends NotificationPermissionService {
  _RecordingPermissionService({
    required this.getStateResult,
    required this.requestStateResult,
  }) : super(
         pushPermissionProvider: _StaticPushPermissionProvider(),
         localPermissionProvider: _StaticLocalPermissionProvider(),
         isApplePlatform: true,
       );

  NotificationPermissionState getStateResult;
  NotificationPermissionState requestStateResult;
  int getPermissionStateCalls = 0;
  int requestPermissionCalls = 0;
  int openSettingsCalls = 0;

  @override
  Future<NotificationPermissionState> getPermissionState({
    required bool enablePush,
    required bool enableLocal,
  }) async {
    getPermissionStateCalls += 1;
    return getStateResult;
  }

  @override
  Future<void> openSettings() async {
    openSettingsCalls += 1;
  }

  @override
  Future<NotificationPermissionState> requestPermission({
    required bool enablePush,
    required bool enableLocal,
  }) async {
    requestPermissionCalls += 1;
    return requestStateResult;
  }
}

class _StaticPushPermissionProvider implements NotificationPushPermissionProvider {
  @override
  Future<NotificationPermissionStatus> getPermissionStatus() async => NotificationPermissionStatus.authorized;

  @override
  Future<NotificationPermissionStatus> requestPermission() async => NotificationPermissionStatus.authorized;
}

class _StaticLocalPermissionProvider implements NotificationLocalPermissionProvider {
  @override
  Future<bool> isPermissionGranted() async => true;

  @override
  Future<bool> requestPermission() async => true;
}
