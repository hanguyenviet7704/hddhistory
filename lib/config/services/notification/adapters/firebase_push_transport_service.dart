part of '../../services.dart';

abstract interface class NotificationPushTransport implements NotificationPushPermissionProvider {
  Future<void> configureForegroundPresentation();
  Future<void> registerBackgroundHandler();
  Stream<TransportRemoteMessage> get foregroundMessages;
  Stream<TransportRemoteMessage> get openedMessages;
  Future<TransportRemoteMessage?> getInitialMessage();
  Future<String?> getToken();
  Stream<String> get tokenRefreshStream;
}

class FirebasePushTransportService implements NotificationPushTransport {
  FirebasePushTransportService({FirebaseMessaging? messaging}) : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  @override
  Stream<TransportRemoteMessage> get foregroundMessages => FirebaseMessaging.onMessage.map(_mapRemoteMessage);

  @override
  Stream<TransportRemoteMessage> get openedMessages => FirebaseMessaging.onMessageOpenedApp.map(_mapRemoteMessage);

  @override
  Future<void> configureForegroundPresentation() {
    LogDev.data('[FirebasePushTransportService] configureForegroundPresentation');
    return _messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: true,
      sound: false,
    );
  }

  @override
  Future<void> registerBackgroundHandler() async {
    LogDev.data('[FirebasePushTransportService] registerBackgroundHandler');
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  @override
  Future<TransportRemoteMessage?> getInitialMessage() async {
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage == null) {
      LogDev.data('[FirebasePushTransportService] getInitialMessage: none');
      return null;
    }
    LogDev.data('[FirebasePushTransportService] getInitialMessage: messageId=${initialMessage.messageId}');
    return _mapRemoteMessage(initialMessage);
  }

  @override
  Future<String?> getToken() async {
    final token = await _messaging.getToken();
    LogDev.data('[FirebasePushTransportService] \r\ngetToken: hasToken=${token?.isNotEmpty ?? false} \r\ntoken=$token');
    return token;
  }

  @override
  Stream<String> get tokenRefreshStream => _messaging.onTokenRefresh;

  @override
  Future<NotificationPermissionStatus> getPermissionStatus() async {
    final settings = await _messaging.getNotificationSettings();
    LogDev.data('[FirebasePushTransportService] getPermissionStatus: ${settings.authorizationStatus}');
    return _mapAuthorizationStatus(settings.authorizationStatus);
  }

  @override
  Future<NotificationPermissionStatus> requestPermission() async {
    LogDev.data('[FirebasePushTransportService] requestPermission');
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      providesAppNotificationSettings: false,
    );

    LogDev.data('[FirebasePushTransportService] requestPermission result: ${settings.authorizationStatus}');
    return _mapAuthorizationStatus(settings.authorizationStatus);
  }

  static TransportRemoteMessage _mapRemoteMessage(RemoteMessage message) {
    return TransportRemoteMessage(
      data: Map<String, dynamic>.from(message.data),
      messageId: message.messageId,
      title: message.notification?.title,
      body: message.notification?.body,
    );
  }

  NotificationPermissionStatus _mapAuthorizationStatus(AuthorizationStatus status) {
    switch (status) {
      case AuthorizationStatus.authorized:
        return NotificationPermissionStatus.authorized;
      case AuthorizationStatus.provisional:
        return NotificationPermissionStatus.provisional;
      case AuthorizationStatus.denied:
        return NotificationPermissionStatus.denied;
      case AuthorizationStatus.notDetermined:
        return NotificationPermissionStatus.notDetermined;
    }
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    LogDev.data('[FirebasePushTransportService] background message: messageId=${message.messageId}');
    await Firebase.initializeApp(options: F.firebaseOptions);

    final router = const NotificationMessageRouter();
    final localNotifications = AwesomeLocalNotificationService();
    final payload = router.fromRemoteMessage(
      FirebasePushTransportService._mapRemoteMessage(message),
      config: const NotificationCoreConfig(),
    );

    if (!payload.hasVisibleContent) {
      LogDev.data('[FirebasePushTransportService] background message skipped: no visible content');
      return;
    }

    await localNotifications.show(router.toLocalRequest(payload));
    LogDev.info('[FirebasePushTransportService] background local notification rendered');
  } catch (error, stackTrace) {
    LogDev.error('[FirebasePushTransportService] background handler failed: $error\n$stackTrace');
  }
}
