// ignore_for_file: depend_on_referenced_packages

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart' as firebase_core_platform;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_messaging_platform_interface/firebase_messaging_platform_interface.dart' as firebase_messaging_platform;
import 'package:flutter_test/flutter_test.dart';
import 'package:meup/config/services/services.dart';
import 'package:meup/flavors.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FirebasePushTransportService', () {
    tearDown(() {
      debugConfigureFirebasePushTransportDependencies();
    });

    test('maps streams and delegates transport operations through injected callbacks', () async {
      final foregroundController = StreamController<RemoteMessage>.broadcast(sync: true);
      final openedController = StreamController<RemoteMessage>.broadcast(sync: true);
      final tokenController = StreamController<String>.broadcast(sync: true);
      final foregroundEvents = <TransportRemoteMessage>[];
      final openedEvents = <TransportRemoteMessage>[];
      final refreshedTokens = <String>[];
      Future<void> Function(RemoteMessage message)? backgroundHandler;
      var configureCalled = false;
      var requestPermissionCalled = false;

      final service = FirebasePushTransportService(
        configureForegroundPresentation: (alert, badge, sound) async {
          configureCalled = !alert && badge && !sound;
        },
        backgroundHandlerRegistrar: (handler) {
          backgroundHandler = handler;
        },
        foregroundRemoteMessages: foregroundController.stream,
        openedRemoteMessages: openedController.stream,
        initialMessageGetter: () async => _remoteMessage(
          messageId: 'initial-1',
          title: 'Initial title',
          body: 'Initial body',
          data: const <String, dynamic>{'type': 'initial'},
        ),
        tokenGetter: () async => 'firebase-token',
        tokenRefreshEvents: tokenController.stream,
        notificationSettingsGetter: () async => _notificationSettings(AuthorizationStatus.authorized),
        permissionRequester: (
          alert,
          badge,
          sound,
          announcement,
          carPlay,
          criticalAlert,
          provisional,
          providesAppNotificationSettings,
        ) async {
          requestPermissionCalled =
              alert &&
              badge &&
              sound &&
              !announcement &&
              !carPlay &&
              !criticalAlert &&
              !provisional &&
              !providesAppNotificationSettings;
          return _notificationSettings(AuthorizationStatus.provisional);
        },
      );
      final foregroundSubscription = service.foregroundMessages.listen(foregroundEvents.add);
      final openedSubscription = service.openedMessages.listen(openedEvents.add);
      final tokenSubscription = service.tokenRefreshStream.listen(refreshedTokens.add);

      await service.configureForegroundPresentation();
      await service.registerBackgroundHandler();
      foregroundController.add(
        _remoteMessage(
          messageId: 'fg-1',
          title: 'Foreground',
          body: 'Foreground body',
          data: const <String, dynamic>{'kind': 'foreground'},
        ),
      );
      openedController.add(
        _remoteMessage(
          messageId: 'open-1',
          title: 'Opened',
          body: 'Opened body',
          data: const <String, dynamic>{'kind': 'opened'},
        ),
      );
      tokenController.add('refresh-token-1');
      await Future<void>.delayed(Duration.zero);

      final initialMessage = await service.getInitialMessage();
      final token = await service.getToken();
      final permissionStatus = await service.getPermissionStatus();
      final requestStatus = await service.requestPermission();

      expect(configureCalled, isTrue);
      expect(backgroundHandler, same(firebaseMessagingBackgroundHandler));
      expect(foregroundEvents.single.messageId, 'fg-1');
      expect(foregroundEvents.single.title, 'Foreground');
      expect(foregroundEvents.single.body, 'Foreground body');
      expect(openedEvents.single.messageId, 'open-1');
      expect(initialMessage?.messageId, 'initial-1');
      expect(token, 'firebase-token');
      expect(permissionStatus, NotificationPermissionStatus.authorized);
      expect(requestStatus, NotificationPermissionStatus.provisional);
      expect(requestPermissionCalled, isTrue);
      expect(refreshedTokens, <String>['refresh-token-1']);

      await foregroundSubscription.cancel();
      await openedSubscription.cancel();
      await tokenSubscription.cancel();
      await foregroundController.close();
      await openedController.close();
      await tokenController.close();
    });

    test('maps null initial messages and denied authorization states', () async {
      final service = FirebasePushTransportService(
        initialMessageGetter: () async => null,
        notificationSettingsGetter: () async => _notificationSettings(AuthorizationStatus.denied),
        permissionRequester: (
          alert,
          badge,
          sound,
          announcement,
          carPlay,
          criticalAlert,
          provisional,
          providesAppNotificationSettings,
        ) async => _notificationSettings(AuthorizationStatus.notDetermined),
      );

      final initialMessage = await service.getInitialMessage();
      final permissionStatus = await service.getPermissionStatus();
      final requestStatus = await service.requestPermission();

      expect(initialMessage, isNull);
      expect(permissionStatus, NotificationPermissionStatus.denied);
      expect(requestStatus, NotificationPermissionStatus.notDetermined);
    });

    test('constructs lazily with default Firebase bindings', () {
      expect(FirebasePushTransportService.new, returnsNormally);
    });

    test('background handler renders a local notification when the payload has visible content', () async {
      final localNotifications = _FakeBackgroundLocalNotifications();
      debugConfigureFirebasePushTransportDependencies(
        initializeApp: () async {},
        localNotificationsFactory: () => localNotifications,
      );

      await firebaseMessagingBackgroundHandler(
        _remoteMessage(
          messageId: 'bg-visible',
          data: const <String, dynamic>{
            'type': 'lesson',
            NotificationConstants.payloadTitleKey: 'Render me',
            NotificationConstants.payloadBodyKey: 'Visible body',
          },
        ),
      );

      expect(localNotifications.shownRequests, hasLength(1));
      expect(localNotifications.shownRequests.single.title, 'Render me');
      expect(localNotifications.shownRequests.single.body, 'Visible body');
    });

    test('background handler skips local rendering when Android system already has a notification payload', () async {
      final localNotifications = _FakeBackgroundLocalNotifications();
      debugConfigureFirebasePushTransportDependencies(
        initializeApp: () async {},
        localNotificationsFactory: () => localNotifications,
      );

      await firebaseMessagingBackgroundHandler(
        _remoteMessage(
          messageId: 'bg-system',
          title: 'System rendered',
          body: 'Handled by Android',
          data: const <String, dynamic>{'type': 'lesson'},
        ),
      );

      expect(localNotifications.shownRequests, isEmpty);
    });

    test('background handler skips invisible payloads and swallows failures', () async {
      final localNotifications = _FakeBackgroundLocalNotifications();
      debugConfigureFirebasePushTransportDependencies(
        initializeApp: () async {},
        localNotificationsFactory: () => localNotifications,
      );

      await firebaseMessagingBackgroundHandler(
        _remoteMessage(
          messageId: 'bg-empty',
          data: const <String, dynamic>{'type': 'silent'},
        ),
      );

      expect(localNotifications.shownRequests, isEmpty);

      debugConfigureFirebasePushTransportDependencies(
        initializeApp: () async {
          throw StateError('init failed');
        },
        localNotificationsFactory: () => localNotifications,
      );

      await firebaseMessagingBackgroundHandler(
        _remoteMessage(
          messageId: 'bg-error',
          title: 'Should not throw',
          body: 'Still swallowed',
        ),
      );
    });

    test('uses default Firebase platform bindings when platform interfaces are mocked', () async {
      final originalFirebasePlatform = firebase_core_platform.FirebasePlatform.instance;
      final originalFirebaseDelegate = Firebase.delegatePackingProperty;
      final originalMessagingPlatform = firebase_messaging_platform.FirebaseMessagingPlatform.instance;
      final firebasePlatform = _FakeFirebasePlatform();
      final messagingPlatform = _FakeFirebaseMessagingPlatform(
        initialMessage: _remoteMessage(
          messageId: 'default-initial',
          title: 'Default initial',
          body: 'Opened from platform',
          data: const <String, dynamic>{'kind': 'default'},
        ),
        token: 'default-token',
        notificationSettings: _notificationSettings(AuthorizationStatus.authorized),
        requestPermissionResult: _notificationSettings(AuthorizationStatus.provisional),
      );
      firebase_core_platform.FirebasePlatform.instance = firebasePlatform;
      Firebase.delegatePackingProperty = null;
      firebase_messaging_platform.FirebaseMessagingPlatform.instance = messagingPlatform;
      addTearDown(() async {
        await messagingPlatform.dispose();
        firebase_messaging_platform.FirebaseMessagingPlatform.instance = originalMessagingPlatform;
        firebase_core_platform.FirebasePlatform.instance = originalFirebasePlatform;
        Firebase.delegatePackingProperty = originalFirebaseDelegate;
      });

      await Firebase.initializeApp(options: _testFirebaseOptions);

      final service = FirebasePushTransportService();
      final refreshedTokens = <String>[];
      final refreshSubscription = service.tokenRefreshStream.listen(refreshedTokens.add);

      await service.configureForegroundPresentation();
      await service.registerBackgroundHandler();
      messagingPlatform.tokenRefreshController.add('default-refresh');
      await Future<void>.delayed(Duration.zero);

      final initialMessage = await service.getInitialMessage();
      final token = await service.getToken();
      final permissionStatus = await service.getPermissionStatus();
      final requestStatus = await service.requestPermission();

      expect(messagingPlatform.foregroundPresentationRequests, <List<bool>>[
        <bool>[false, true, false],
      ]);
      expect(messagingPlatform.backgroundHandler, same(firebaseMessagingBackgroundHandler));
      expect(initialMessage?.messageId, 'default-initial');
      expect(token, 'default-token');
      expect(permissionStatus, NotificationPermissionStatus.authorized);
      expect(requestStatus, NotificationPermissionStatus.provisional);
      expect(refreshedTokens, <String>['default-refresh']);

      await refreshSubscription.cancel();
    });

    test('background handler can use the default firebase initialize and local factory for invisible payloads', () async {
      final originalFirebasePlatform = firebase_core_platform.FirebasePlatform.instance;
      final originalFirebaseDelegate = Firebase.delegatePackingProperty;
      final originalFlavor = F.appFlavor;
      final firebasePlatform = _FakeFirebasePlatform();
      firebase_core_platform.FirebasePlatform.instance = firebasePlatform;
      Firebase.delegatePackingProperty = null;
      F.appFlavor = Flavor.dev;
      addTearDown(() {
        firebase_core_platform.FirebasePlatform.instance = originalFirebasePlatform;
        Firebase.delegatePackingProperty = originalFirebaseDelegate;
        F.appFlavor = originalFlavor;
      });

      await firebaseMessagingBackgroundHandler(
        _remoteMessage(
          messageId: 'bg-default-init',
          data: const <String, dynamic>{'type': 'silent'},
        ),
      );

      expect(firebasePlatform.initializeAppCallCount, 1);
      expect(firebasePlatform.apps, hasLength(1));
    });
  });
}

RemoteMessage _remoteMessage({
  String? messageId,
  String? title,
  String? body,
  Map<String, dynamic> data = const <String, dynamic>{},
}) {
  return RemoteMessage.fromMap(<String, dynamic>{
    'messageId': messageId,
    'data': data,
    if (title != null || body != null)
      'notification': <String, dynamic>{
        'title': title,
        'body': body,
      },
  });
}

NotificationSettings _notificationSettings(AuthorizationStatus status) {
  return NotificationSettings(
    alert: AppleNotificationSetting.enabled,
    announcement: AppleNotificationSetting.notSupported,
    authorizationStatus: status,
    badge: AppleNotificationSetting.enabled,
    carPlay: AppleNotificationSetting.notSupported,
    lockScreen: AppleNotificationSetting.enabled,
    notificationCenter: AppleNotificationSetting.enabled,
    showPreviews: AppleShowPreviewSetting.always,
    timeSensitive: AppleNotificationSetting.notSupported,
    criticalAlert: AppleNotificationSetting.disabled,
    sound: AppleNotificationSetting.enabled,
    providesAppNotificationSettings: AppleNotificationSetting.disabled,
  );
}

class _FakeBackgroundLocalNotifications implements NotificationLocalNotifications {
  final List<NotificationRequest> shownRequests = <NotificationRequest>[];

  @override
  Stream<TransportLocalAction> get actionStream => const Stream<TransportLocalAction>.empty();

  @override
  Future<void> cancel(int id) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> cancelAllSchedules() async {}

  @override
  Future<void> cancelSchedule(int id) async {}

  @override
  Future<void> dispose() async {}

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
  Future<void> show(NotificationRequest request) async => shownRequests.add(request);
}

class _FakeFirebasePlatform extends firebase_core_platform.FirebasePlatform {
  final Map<String, firebase_core_platform.FirebaseAppPlatform> _apps =
      <String, firebase_core_platform.FirebaseAppPlatform>{};
  int initializeAppCallCount = 0;

  @override
  List<firebase_core_platform.FirebaseAppPlatform> get apps => _apps.values.toList(growable: false);

  @override
  firebase_core_platform.FirebaseAppPlatform app([
    String name = firebase_core_platform.defaultFirebaseAppName,
  ]) {
    final app = _apps[name];
    if (app == null) {
      throw FirebaseException(plugin: 'firebase_core', message: 'No Firebase App $name');
    }
    return app;
  }

  @override
  Future<firebase_core_platform.FirebaseAppPlatform> initializeApp({
    String? name,
    firebase_core_platform.FirebaseOptions? options,
  }) async {
    initializeAppCallCount += 1;
    final appName = name ?? firebase_core_platform.defaultFirebaseAppName;
    return _apps.putIfAbsent(
      appName,
      () => firebase_core_platform.FirebaseAppPlatform(
        appName,
        options ?? _testFirebaseOptions,
      ),
    );
  }
}

class _FakeFirebaseMessagingPlatform extends firebase_messaging_platform.FirebaseMessagingPlatform {
  _FakeFirebaseMessagingPlatform({
    this.initialMessage,
    this.token,
    NotificationSettings? notificationSettings,
    NotificationSettings? requestPermissionResult,
    StreamController<String>? tokenRefreshController,
    FirebaseApp? app,
  }) : notificationSettings = notificationSettings ?? _notificationSettings(AuthorizationStatus.authorized),
       requestPermissionResult = requestPermissionResult ?? _notificationSettings(AuthorizationStatus.authorized),
       tokenRefreshController = tokenRefreshController ?? StreamController<String>.broadcast(sync: true),
       super(appInstance: app);

  final RemoteMessage? initialMessage;
  final String? token;
  final NotificationSettings notificationSettings;
  final NotificationSettings requestPermissionResult;
  final StreamController<String> tokenRefreshController;
  final List<List<bool>> foregroundPresentationRequests = <List<bool>>[];
  BackgroundMessageHandler? backgroundHandler;
  bool _isAutoInitEnabled = true;

  Future<void> dispose() => tokenRefreshController.close();

  @override
  firebase_messaging_platform.FirebaseMessagingPlatform delegateFor({required FirebaseApp app}) {
    return this;
  }

  @override
  firebase_messaging_platform.FirebaseMessagingPlatform setInitialValues({bool? isAutoInitEnabled}) {
    _isAutoInitEnabled = isAutoInitEnabled ?? _isAutoInitEnabled;
    return this;
  }

  @override
  bool get isAutoInitEnabled => _isAutoInitEnabled;

  @override
  Future<RemoteMessage?> getInitialMessage() async => initialMessage;

  @override
  void registerBackgroundMessageHandler(BackgroundMessageHandler handler) {
    backgroundHandler = handler;
  }

  @override
  Future<String?> getToken({String? vapidKey}) async => token;

  @override
  Stream<String> get onTokenRefresh => tokenRefreshController.stream;

  @override
  Future<NotificationSettings> getNotificationSettings() async => notificationSettings;

  @override
  Future<NotificationSettings> requestPermission({
    bool alert = true,
    bool announcement = false,
    bool badge = true,
    bool carPlay = false,
    bool criticalAlert = false,
    bool provisional = false,
    bool sound = true,
    bool providesAppNotificationSettings = false,
  }) async => requestPermissionResult;

  @override
  Future<void> setForegroundNotificationPresentationOptions({
    required bool alert,
    required bool badge,
    required bool sound,
  }) async {
    foregroundPresentationRequests.add(<bool>[alert, badge, sound]);
  }
}

const FirebaseOptions _testFirebaseOptions = FirebaseOptions(
  apiKey: 'api-key',
  appId: 'app-id',
  messagingSenderId: 'sender-id',
  projectId: 'project-id',
);
