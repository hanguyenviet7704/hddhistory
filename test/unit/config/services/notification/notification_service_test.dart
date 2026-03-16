import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:meup/config/services/services.dart';

void main() {
  group('NotificationService', () {
    test('boots through the bootstrap layer only once and emits token refresh state', () async {
      final pushTransport = _FakePushTransport(token: 'initial-token');
      final localNotifications = _FakeLocalNotifications();
      final permissionService = NotificationPermissionService(
        pushPermissionProvider: pushTransport,
        localPermissionProvider: localNotifications,
        isApplePlatform: true,
      );
      final service = NotificationService(
        pushTransport: pushTransport,
        localNotifications: localNotifications,
        permissionService: permissionService,
      );
      final tokenEvents = <NotificationTokenState>[];
      final subscription = service.tokenRefreshStreamInternal.listen(tokenEvents.add);

      await service.initializeInternal(const NotificationCoreConfig());
      await service.initializeInternal(const NotificationCoreConfig());
      pushTransport.emitTokenRefresh('refresh-token');
      await Future<void>.delayed(Duration.zero);

      expect(localNotifications.initializeCalls, 1);
      expect(localNotifications.registerCalls, 1);
      expect(pushTransport.configureCalls, 1);
      expect(pushTransport.backgroundHandlerCalls, 1);
      expect(tokenEvents.map((event) => event.token), <String>['refresh-token']);
      expect(tokenEvents.single.isFromRefresh, isTrue);

      await subscription.cancel();
      await service.dispose();
      await pushTransport.dispose();
    });

    test('returns the cached token before falling back to transport lookups', () async {
      final pushTransport = _FakePushTransport(token: 'cached-token');
      final service = NotificationService(
        pushTransport: pushTransport,
        localNotifications: _FakeLocalNotifications(),
        permissionService: NotificationPermissionService(
          pushPermissionProvider: pushTransport,
          localPermissionProvider: _FakeLocalNotifications(),
          isApplePlatform: true,
        ),
      );

      await service.initializeInternal(const NotificationCoreConfig());
      final token = await service.getTokenInternal();

      expect(token, 'cached-token');
      expect(pushTransport.getTokenCalls, 1);

      await service.dispose();
      await pushTransport.dispose();
    });

    test('does not render or schedule local notifications when local is disabled', () async {
      final pushTransport = _FakePushTransport();
      final localNotifications = _FakeLocalNotifications();
      final service = NotificationService(
        pushTransport: pushTransport,
        localNotifications: localNotifications,
        permissionService: NotificationPermissionService(
          pushPermissionProvider: pushTransport,
          localPermissionProvider: localNotifications,
          isApplePlatform: true,
        ),
      );

      await service.initializeInternal(const NotificationCoreConfig(enableLocal: false));
      await service.showLocalInternal(const NotificationRequest(title: 'Ignored'));
      await service.scheduleLocalInternal(
        const NotificationScheduleRequest(
          notification: NotificationRequest(title: 'Ignored'),
          interval: Duration(minutes: 30),
        ),
      );

      expect(localNotifications.showCalls, 0);
      expect(localNotifications.scheduleCalls, 0);

      await service.dispose();
      await pushTransport.dispose();
    });
  });
}

class _FakePushTransport implements NotificationPushTransport {
  _FakePushTransport({
    this.token,
  });

  final StreamController<TransportRemoteMessage> _foregroundController = StreamController<TransportRemoteMessage>.broadcast(sync: true);
  final StreamController<TransportRemoteMessage> _openedController = StreamController<TransportRemoteMessage>.broadcast(sync: true);
  final StreamController<String> _tokenController = StreamController<String>.broadcast(sync: true);
  String? token;
  int configureCalls = 0;
  int backgroundHandlerCalls = 0;
  int getTokenCalls = 0;

  @override
  Future<void> configureForegroundPresentation() async => configureCalls += 1;

  Future<void> dispose() async {
    await _foregroundController.close();
    await _openedController.close();
    await _tokenController.close();
  }

  void emitTokenRefresh(String value) {
    _tokenController.add(value);
  }

  @override
  Stream<TransportRemoteMessage> get foregroundMessages => _foregroundController.stream;

  @override
  Future<TransportRemoteMessage?> getInitialMessage() async => null;

  @override
  Future<NotificationPermissionStatus> getPermissionStatus() async => NotificationPermissionStatus.authorized;

  @override
  Future<String?> getToken() async {
    getTokenCalls += 1;
    return token;
  }

  @override
  Stream<TransportRemoteMessage> get openedMessages => _openedController.stream;

  @override
  Future<void> registerBackgroundHandler() async => backgroundHandlerCalls += 1;

  @override
  Future<NotificationPermissionStatus> requestPermission() async => NotificationPermissionStatus.authorized;

  @override
  Stream<String> get tokenRefreshStream => _tokenController.stream;
}

class _FakeLocalNotifications implements NotificationLocalNotifications {
  final StreamController<TransportLocalAction> _controller = StreamController<TransportLocalAction>.broadcast(sync: true);

  int initializeCalls = 0;
  int registerCalls = 0;
  int showCalls = 0;
  int scheduleCalls = 0;

  @override
  Stream<TransportLocalAction> get actionStream => _controller.stream;

  @override
  Future<void> cancel(int id) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> cancelAllSchedules() async {}

  @override
  Future<void> cancelSchedule(int id) async {}

  @override
  Future<void> dispose() => _controller.close();

  @override
  Future<TransportLocalAction?> getInitialAction() async => null;

  @override
  Future<void> initialize() async => initializeCalls += 1;

  @override
  Future<bool> isPermissionGranted() async => true;

  @override
  Future<void> registerListeners() async => registerCalls += 1;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> schedule(NotificationScheduleRequest request) async => scheduleCalls += 1;

  @override
  Future<void> show(NotificationRequest request) async => showCalls += 1;
}
