import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:meup/config/services/services.dart';

void main() {
  group('NotificationBootstrapService', () {
    test('initializes local and push once, requests permission, and restores the initial remote interaction', () async {
      final pushTransport = _FakePushTransport(
        token: 'initial-token',
        initialMessage: const TransportRemoteMessage(
          data: <String, dynamic>{'type': 'lesson', 'entityId': '42'},
          messageId: 'msg-42',
          title: 'Continue learning',
          body: 'Resume your lesson',
        ),
      );
      final localNotifications = _FakeLocalNotifications();
      final interactionService = NotificationInteractionService();
      final interactions = <NotificationInteraction>[];
      final subscription = interactionService.stream.listen(interactions.add);
      final bootstrap = _buildBootstrap(
        pushTransport: pushTransport,
        localNotifications: localNotifications,
        interactionService: interactionService,
      );

      await bootstrap.initialize(
        config: const NotificationCoreConfig(autoRequestPermissionOnInit: true),
      );
      await bootstrap.initialize(
        config: const NotificationCoreConfig(autoRequestPermissionOnInit: true),
      );

      expect(localNotifications.initializeCalls, 1);
      expect(localNotifications.registerCalls, 1);
      expect(pushTransport.configureCalls, 1);
      expect(pushTransport.backgroundHandlerCalls, 1);
      expect(pushTransport.requestPermissionCalls, 1);
      expect(interactions, hasLength(1));
      expect(interactions.single.type, NotificationInteractionType.coldStart);
      expect(interactions.single.payload.source, NotificationPayloadSource.remote);
      expect(interactions.single.payload.sourceId, 'msg-42');

      await subscription.cancel();
      await bootstrap.dispose();
      await interactionService.dispose();
    });

    test('publishes foreground interactions and renders a local notification when policy allows it', () async {
      final pushTransport = _FakePushTransport();
      final localNotifications = _FakeLocalNotifications();
      final interactionService = NotificationInteractionService();
      final interactions = <NotificationInteraction>[];
      final subscription = interactionService.stream.listen(interactions.add);
      final bootstrap = _buildBootstrap(
        pushTransport: pushTransport,
        localNotifications: localNotifications,
        interactionService: interactionService,
      );

      await bootstrap.initialize(config: const NotificationCoreConfig());
      pushTransport.emitForeground(
        const TransportRemoteMessage(
          data: <String, dynamic>{'type': 'promo'},
          messageId: 'fg-1',
          title: 'Limited offer',
          body: 'Open for details',
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(interactions, hasLength(1));
      expect(interactions.single.type, NotificationInteractionType.foregroundReceived);
      expect(localNotifications.shownRequests, hasLength(1));
      expect(localNotifications.shownRequests.single.title, 'Limited offer');
      expect(localNotifications.shownRequests.single.body, 'Open for details');

      await subscription.cancel();
      await bootstrap.dispose();
      await interactionService.dispose();
    });

    test('normalizes oversized remote ids before rendering foreground local notifications', () async {
      final pushTransport = _FakePushTransport();
      final localNotifications = _FakeLocalNotifications();
      final interactionService = NotificationInteractionService();
      final bootstrap = _buildBootstrap(
        pushTransport: pushTransport,
        localNotifications: localNotifications,
        interactionService: interactionService,
      );

      await bootstrap.initialize(config: const NotificationCoreConfig());
      pushTransport.emitForeground(
        const TransportRemoteMessage(
          data: <String, dynamic>{'type': 'promo'},
          messageId: '9223372036854775807',
          title: 'Oversized message id',
          body: 'Should still render on iOS',
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(localNotifications.shownRequests, hasLength(1));
      expect(localNotifications.shownRequests.single.id, isNotNull);
      expect(
        localNotifications.shownRequests.single.id,
        allOf(
          greaterThanOrEqualTo(-0x80000000),
          lessThanOrEqualTo(0x7FFFFFFF),
        ),
      );

      await bootstrap.dispose();
      await interactionService.dispose();
    });

    test('publishes foreground interactions but skips rendering when policy blocks it', () async {
      final pushTransport = _FakePushTransport();
      final localNotifications = _FakeLocalNotifications();
      final interactionService = NotificationInteractionService();
      final interactions = <NotificationInteraction>[];
      final subscription = interactionService.stream.listen(interactions.add);
      final bootstrap = _buildBootstrap(
        pushTransport: pushTransport,
        localNotifications: localNotifications,
        interactionService: interactionService,
      );

      await bootstrap.initialize(
        config: NotificationCoreConfig(
          shouldRenderForegroundNotification: (_) => false,
        ),
      );
      pushTransport.emitForeground(
        const TransportRemoteMessage(
          data: <String, dynamic>{'type': 'promo'},
          messageId: 'fg-2',
          title: 'Blocked offer',
          body: 'Do not render',
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(interactions, hasLength(1));
      expect(interactions.single.type, NotificationInteractionType.foregroundReceived);
      expect(localNotifications.shownRequests, isEmpty);

      await subscription.cancel();
      await bootstrap.dispose();
      await interactionService.dispose();
    });

    test('maps opened remote messages and local actions into the correct interaction types', () async {
      final pushTransport = _FakePushTransport();
      final localNotifications = _FakeLocalNotifications();
      final interactionService = NotificationInteractionService();
      final interactions = <NotificationInteraction>[];
      final subscription = interactionService.stream.listen(interactions.add);
      final bootstrap = _buildBootstrap(
        pushTransport: pushTransport,
        localNotifications: localNotifications,
        interactionService: interactionService,
      );

      await bootstrap.initialize(config: const NotificationCoreConfig());
      pushTransport.emitOpened(
        const TransportRemoteMessage(
          data: <String, dynamic>{'type': 'opened'},
          messageId: 'opened-1',
          title: 'Opened',
        ),
      );
      localNotifications.emitAction(
        TransportLocalAction(
          id: 1,
          title: 'Foreground local',
          payload: const <String, String>{'type': 'local'},
          performedAt: DateTime(2026, 1, 1),
        ),
      );
      localNotifications.emitAction(
        TransportLocalAction(
          id: 2,
          title: 'Background local',
          payload: const <String, String>{'type': 'background'},
          performedAt: DateTime(2026, 1, 2),
          fromBackground: true,
        ),
      );
      localNotifications.emitAction(
        TransportLocalAction(
          id: 3,
          title: 'Terminated local',
          payload: const <String, String>{'type': 'terminated'},
          performedAt: DateTime(2026, 1, 3),
          fromTerminated: true,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(
        interactions.map((interaction) => interaction.type),
        <NotificationInteractionType>[
          NotificationInteractionType.openedApp,
          NotificationInteractionType.localAction,
          NotificationInteractionType.openedApp,
          NotificationInteractionType.coldStart,
        ],
      );

      await subscription.cancel();
      await bootstrap.dispose();
      await interactionService.dispose();
    });

    test('restores the initial local interaction when there is no initial remote message', () async {
      final pushTransport = _FakePushTransport();
      final localNotifications = _FakeLocalNotifications(
        initialAction: TransportLocalAction(
          id: 8,
          title: 'Local cold start',
          payload: const <String, String>{'type': 'lesson'},
          performedAt: DateTime(2026, 2, 1),
          fromTerminated: true,
        ),
      );
      final interactionService = NotificationInteractionService();
      final interactions = <NotificationInteraction>[];
      final subscription = interactionService.stream.listen(interactions.add);
      final bootstrap = _buildBootstrap(
        pushTransport: pushTransport,
        localNotifications: localNotifications,
        interactionService: interactionService,
      );

      await bootstrap.initialize(config: const NotificationCoreConfig());

      expect(interactions, hasLength(1));
      expect(interactions.single.type, NotificationInteractionType.coldStart);
      expect(interactions.single.payload.source, NotificationPayloadSource.local);
      expect(interactions.single.payload.sourceId, '8');

      await subscription.cancel();
      await bootstrap.dispose();
      await interactionService.dispose();
    });

    test('dispose cancels push and local subscriptions', () async {
      final pushTransport = _FakePushTransport();
      final localNotifications = _FakeLocalNotifications();
      final interactionService = NotificationInteractionService();
      final interactions = <NotificationInteraction>[];
      final subscription = interactionService.stream.listen(interactions.add);
      final bootstrap = _buildBootstrap(
        pushTransport: pushTransport,
        localNotifications: localNotifications,
        interactionService: interactionService,
      );

      await bootstrap.initialize(config: const NotificationCoreConfig());
      await bootstrap.dispose();

      pushTransport.emitForeground(
        const TransportRemoteMessage(
          data: <String, dynamic>{'type': 'promo'},
          title: 'Ignored',
          body: 'Ignored',
        ),
      );
      pushTransport.emitOpened(
        const TransportRemoteMessage(
          data: <String, dynamic>{'type': 'opened'},
          title: 'Ignored',
        ),
      );
      localNotifications.emitAction(
        TransportLocalAction(
          id: 99,
          payload: const <String, String>{'type': 'ignored'},
          performedAt: DateTime(2026, 3, 1),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(interactions, isEmpty);
      expect(localNotifications.shownRequests, isEmpty);

      await subscription.cancel();
      await interactionService.dispose();
    });
  });
}

NotificationBootstrapService _buildBootstrap({
  required _FakePushTransport pushTransport,
  required _FakeLocalNotifications localNotifications,
  required NotificationInteractionService interactionService,
}) {
  final tokenService = NotificationTokenService();
  final permissionService = NotificationPermissionService(
    pushPermissionProvider: pushTransport,
    localPermissionProvider: localNotifications,
    isApplePlatform: true,
  );

  return NotificationBootstrapService(
    pushTransport: pushTransport,
    localNotifications: localNotifications,
    messageRouter: const NotificationMessageRouter(),
    interactionService: interactionService,
    tokenService: tokenService,
    foregroundPolicy: const NotificationForegroundPolicy(),
    permissionService: permissionService,
  );
}

class _FakePushTransport implements NotificationPushTransport {
  _FakePushTransport({
    this.token,
    this.initialMessage,
  });

  final StreamController<TransportRemoteMessage> _foregroundController = StreamController<TransportRemoteMessage>.broadcast(sync: true);
  final StreamController<TransportRemoteMessage> _openedController = StreamController<TransportRemoteMessage>.broadcast(sync: true);
  final StreamController<String> _tokenController = StreamController<String>.broadcast(sync: true);
  String? token;
  TransportRemoteMessage? initialMessage;
  NotificationPermissionStatus permissionStatus = NotificationPermissionStatus.authorized;
  int configureCalls = 0;
  int backgroundHandlerCalls = 0;
  int requestPermissionCalls = 0;

  void emitForeground(TransportRemoteMessage message) {
    _foregroundController.add(message);
  }

  void emitOpened(TransportRemoteMessage message) {
    _openedController.add(message);
  }

  @override
  Future<void> configureForegroundPresentation() async => configureCalls += 1;

  @override
  Stream<TransportRemoteMessage> get foregroundMessages => _foregroundController.stream;

  @override
  Future<TransportRemoteMessage?> getInitialMessage() async => initialMessage;

  @override
  Future<NotificationPermissionStatus> getPermissionStatus() async => permissionStatus;

  @override
  Future<String?> getToken() async => token;

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
    this.initialAction,
  });

  final StreamController<TransportLocalAction> _actionController = StreamController<TransportLocalAction>.broadcast(sync: true);
  final List<NotificationRequest> shownRequests = <NotificationRequest>[];
  TransportLocalAction? initialAction;
  bool permissionGranted = true;
  bool requestPermissionResult = true;
  int initializeCalls = 0;
  int registerCalls = 0;

  void emitAction(TransportLocalAction action) {
    _actionController.add(action);
  }

  @override
  Stream<TransportLocalAction> get actionStream => _actionController.stream;

  @override
  Future<void> cancel(int id) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> cancelAllSchedules() async {}

  @override
  Future<void> cancelSchedule(int id) async {}

  @override
  Future<void> dispose() => _actionController.close();

  @override
  Future<TransportLocalAction?> getInitialAction() async => initialAction;

  @override
  Future<void> initialize() async => initializeCalls += 1;

  @override
  Future<bool> isPermissionGranted() async => permissionGranted;

  @override
  Future<void> registerListeners() async => registerCalls += 1;

  @override
  Future<bool> requestPermission() async => requestPermissionResult;

  @override
  Future<void> schedule(NotificationScheduleRequest request) async {}

  @override
  Future<void> show(NotificationRequest request) async => shownRequests.add(request);
}
