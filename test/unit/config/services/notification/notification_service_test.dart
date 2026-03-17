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

      await service.initializeInternal(const NotificationCoreConfig());
      final token = await service.getTokenInternal();

      expect(token, 'cached-token');
      expect(pushTransport.getTokenCalls, 1);

      await service.dispose();
      await pushTransport.dispose();
    });

    test('returns null when push is disabled', () async {
      final pushTransport = _FakePushTransport(token: 'ignored-token');
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

      await service.initializeInternal(const NotificationCoreConfig(enablePush: false));
      final token = await service.getTokenInternal();

      expect(token, isNull);
      expect(pushTransport.getTokenCalls, 0);

      await service.dispose();
      await pushTransport.dispose();
    });

    test('delegates local show schedule cancel and cancelAll when local notifications are enabled', () async {
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
      const request = NotificationRequest(
        id: 9,
        title: 'Practice now',
        body: 'Keep going',
      );
      const scheduleRequest = NotificationScheduleRequest(
        notification: request,
        interval: Duration(minutes: 15),
      );

      await service.initializeInternal(const NotificationCoreConfig());
      await service.showLocalInternal(request);
      await service.scheduleLocalInternal(scheduleRequest);
      await service.cancelInternal(9);
      await service.cancelAllInternal();

      expect(localNotifications.shownRequests, <NotificationRequest>[request]);
      expect(localNotifications.scheduledRequests, <NotificationScheduleRequest>[scheduleRequest]);
      expect(localNotifications.cancelledIds, <int>[9]);
      expect(localNotifications.cancelledScheduleIds, <int>[9]);
      expect(localNotifications.cancelAllCalls, 1);
      expect(localNotifications.cancelAllSchedulesCalls, 1);

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

      expect(localNotifications.shownRequests, isEmpty);
      expect(localNotifications.scheduledRequests, isEmpty);

      await service.dispose();
      await pushTransport.dispose();
    });

    test('passes permission state, request, and settings through the permission service', () async {
      final pushTransport = _FakePushTransport();
      final localNotifications = _FakeLocalNotifications();
      final permissionService = _RecordingPermissionService(
        getStateResult: const NotificationPermissionState(
          status: NotificationPermissionStatus.provisional,
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
      final service = NotificationService(
        pushTransport: pushTransport,
        localNotifications: localNotifications,
        permissionService: permissionService,
      );

      await service.initializeInternal(const NotificationCoreConfig());
      final permissionState = await service.getPermissionStateInternal();
      final requestState = await service.requestPermissionInternal();
      await service.openSettingsInternal();

      expect(permissionState.status, NotificationPermissionStatus.provisional);
      expect(requestState.status, NotificationPermissionStatus.authorized);
      expect(permissionService.getPermissionStateCalls, 1);
      expect(permissionService.requestPermissionCalls, 1);
      expect(permissionService.openSettingsCalls, 1);

      await service.dispose();
      await pushTransport.dispose();
    });

    test('static helpers delegate to the debug instance', () async {
      final pushTransport = _FakePushTransport(token: 'static-token');
      final localNotifications = _FakeLocalNotifications(
        permissionGranted: true,
        requestPermissionResult: true,
      );
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
      final service = NotificationService(
        pushTransport: pushTransport,
        localNotifications: localNotifications,
        permissionService: permissionService,
      );
      final originalInstance = NotificationService.debugInstance;
      final tokenEvents = <NotificationTokenState>[];
      final interactionEvents = <NotificationInteraction>[];

      NotificationService.debugSetInstance(service);
      addTearDown(() {
        if (originalInstance == null) {
          NotificationService.debugResetInstance();
          return;
        }
        NotificationService.debugSetInstance(originalInstance);
      });

      await NotificationService.initialize(const NotificationCoreConfig());
      final tokenSubscription = NotificationService.tokenRefreshStream.listen(tokenEvents.add);
      final interactionSubscription = NotificationService.interactionStream.listen(interactionEvents.add);

      final permissionState = await NotificationService.getPermissionState();
      final requestState = await NotificationService.requestPermission();
      await NotificationService.openSettings();
      final token = await NotificationService.getToken();
      await NotificationService.showLocal(const NotificationRequest(id: 3, title: 'Static show'));
      await NotificationService.scheduleLocal(
        const NotificationScheduleRequest(
          notification: NotificationRequest(id: 3, title: 'Static schedule'),
          interval: Duration(hours: 1),
        ),
      );
      await NotificationService.cancel(3);
      await NotificationService.cancelAll();

      expect(permissionState.status, NotificationPermissionStatus.authorized);
      expect(requestState.status, NotificationPermissionStatus.authorized);
      expect(token, 'static-token');
      expect(localNotifications.shownRequests.single.title, 'Static show');
      expect(localNotifications.scheduledRequests.single.notification.title, 'Static schedule');
      expect(localNotifications.cancelledIds, <int>[3]);
      expect(localNotifications.cancelledScheduleIds, <int>[3]);
      expect(localNotifications.cancelAllCalls, 1);
      expect(localNotifications.cancelAllSchedulesCalls, 1);
      expect(tokenEvents, isEmpty);
      expect(interactionEvents, isEmpty);

      await tokenSubscription.cancel();
      await interactionSubscription.cancel();
      await service.dispose();
      await pushTransport.dispose();
    });

    test('constructs the default notification graph lazily', () {
      expect(NotificationService.new, returnsNormally);
    });
  });
}

class _FakePushTransport implements NotificationPushTransport {
  _FakePushTransport({
    this.token,
  });

  final StreamController<TransportRemoteMessage> _foregroundController =
      StreamController<TransportRemoteMessage>.broadcast(sync: true);
  final StreamController<TransportRemoteMessage> _openedController =
      StreamController<TransportRemoteMessage>.broadcast(sync: true);
  final StreamController<String> _tokenController = StreamController<String>.broadcast(sync: true);

  String? token;
  TransportRemoteMessage? initialMessage;
  NotificationPermissionStatus permissionStatus = NotificationPermissionStatus.authorized;
  int configureCalls = 0;
  int backgroundHandlerCalls = 0;
  int getTokenCalls = 0;
  int getPermissionStatusCalls = 0;
  int requestPermissionCalls = 0;

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
  Future<TransportRemoteMessage?> getInitialMessage() async => initialMessage;

  @override
  Future<NotificationPermissionStatus> getPermissionStatus() async {
    getPermissionStatusCalls += 1;
    return permissionStatus;
  }

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
  Future<NotificationPermissionStatus> requestPermission() async {
    requestPermissionCalls += 1;
    return permissionStatus;
  }

  @override
  Stream<String> get tokenRefreshStream => _tokenController.stream;
}

class _FakeLocalNotifications implements NotificationLocalNotifications {
  _FakeLocalNotifications({
    this.permissionGranted = true,
    this.requestPermissionResult = true,
  });

  final StreamController<TransportLocalAction> _controller =
      StreamController<TransportLocalAction>.broadcast(sync: true);
  final List<NotificationRequest> shownRequests = <NotificationRequest>[];
  final List<NotificationScheduleRequest> scheduledRequests = <NotificationScheduleRequest>[];
  final List<int> cancelledIds = <int>[];
  final List<int> cancelledScheduleIds = <int>[];
  bool permissionGranted;
  bool requestPermissionResult;
  int initializeCalls = 0;
  int registerCalls = 0;
  int cancelAllCalls = 0;
  int cancelAllSchedulesCalls = 0;
  int isPermissionGrantedCalls = 0;
  int requestPermissionCalls = 0;

  @override
  Stream<TransportLocalAction> get actionStream => _controller.stream;

  @override
  Future<void> cancel(int id) async => cancelledIds.add(id);

  @override
  Future<void> cancelAll() async => cancelAllCalls += 1;

  @override
  Future<void> cancelAllSchedules() async => cancelAllSchedulesCalls += 1;

  @override
  Future<void> cancelSchedule(int id) async => cancelledScheduleIds.add(id);

  @override
  Future<void> dispose() => _controller.close();

  @override
  Future<TransportLocalAction?> getInitialAction() async => null;

  @override
  Future<void> initialize() async => initializeCalls += 1;

  @override
  Future<bool> isPermissionGranted() async {
    isPermissionGrantedCalls += 1;
    return permissionGranted;
  }

  @override
  Future<void> registerListeners() async => registerCalls += 1;

  @override
  Future<bool> requestPermission() async {
    requestPermissionCalls += 1;
    return requestPermissionResult;
  }

  @override
  Future<void> schedule(NotificationScheduleRequest request) async => scheduledRequests.add(request);

  @override
  Future<void> show(NotificationRequest request) async => shownRequests.add(request);
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

  final NotificationPermissionState getStateResult;
  final NotificationPermissionState requestStateResult;
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
