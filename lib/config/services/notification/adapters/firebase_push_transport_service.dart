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

typedef FirebasePushTransportForegroundPresentationSetter =
    Future<void> Function(bool alert, bool badge, bool sound);
typedef FirebasePushTransportBackgroundRegistrar = void Function(BackgroundMessageHandler handler);
typedef FirebasePushTransportInitialMessageGetter = Future<RemoteMessage?> Function();
typedef FirebasePushTransportTokenGetter = Future<String?> Function();
typedef FirebasePushTransportNotificationSettingsGetter = Future<NotificationSettings> Function();
typedef FirebasePushTransportPermissionRequester =
    Future<NotificationSettings> Function(
      bool alert,
      bool badge,
      bool sound,
      bool announcement,
      bool carPlay,
      bool criticalAlert,
      bool provisional,
      bool providesAppNotificationSettings,
    );

Future<void> _defaultFirebasePushTransportInitializeApp() async {
  await Firebase.initializeApp(options: F.firebaseOptions);
}

NotificationMessageRouter _defaultFirebasePushTransportMessageRouterFactory() => const NotificationMessageRouter();

NotificationLocalNotifications _defaultFirebasePushTransportLocalNotificationsFactory() {
  return AwesomeLocalNotificationService();
}

Future<void> _defaultFirebasePushTransportConfigureForegroundPresentation(bool alert, bool badge, bool sound) {
  return FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: alert,
    badge: badge,
    sound: sound,
  );
}

Future<RemoteMessage?> _defaultFirebasePushTransportGetInitialMessage() {
  return FirebaseMessaging.instance.getInitialMessage();
}

Future<String?> _defaultFirebasePushTransportGetToken() {
  return FirebaseMessaging.instance.getToken();
}

Stream<String> _defaultFirebasePushTransportTokenRefreshStream() {
  return FirebaseMessaging.instance.onTokenRefresh;
}

Future<NotificationSettings> _defaultFirebasePushTransportGetNotificationSettings() {
  return FirebaseMessaging.instance.getNotificationSettings();
}

Future<NotificationSettings> _defaultFirebasePushTransportRequestPermission(
  bool alert,
  bool badge,
  bool sound,
  bool announcement,
  bool carPlay,
  bool criticalAlert,
  bool provisional,
  bool providesAppNotificationSettings,
) {
  return FirebaseMessaging.instance.requestPermission(
    alert: alert,
    badge: badge,
    sound: sound,
    announcement: announcement,
    carPlay: carPlay,
    criticalAlert: criticalAlert,
    provisional: provisional,
    providesAppNotificationSettings: providesAppNotificationSettings,
  );
}

Future<void> Function() _firebasePushTransportInitializeApp = _defaultFirebasePushTransportInitializeApp;
NotificationMessageRouter Function() _firebasePushTransportMessageRouterFactory =
    _defaultFirebasePushTransportMessageRouterFactory;
NotificationLocalNotifications Function() _firebasePushTransportLocalNotificationsFactory =
    _defaultFirebasePushTransportLocalNotificationsFactory;

@visibleForTesting
void debugConfigureFirebasePushTransportDependencies({
  Future<void> Function()? initializeApp,
  NotificationMessageRouter Function()? messageRouterFactory,
  NotificationLocalNotifications Function()? localNotificationsFactory,
}) {
  _firebasePushTransportInitializeApp = initializeApp ?? _defaultFirebasePushTransportInitializeApp;
  _firebasePushTransportMessageRouterFactory =
      messageRouterFactory ?? _defaultFirebasePushTransportMessageRouterFactory;
  _firebasePushTransportLocalNotificationsFactory =
      localNotificationsFactory ?? _defaultFirebasePushTransportLocalNotificationsFactory;
}

class FirebasePushTransportService implements NotificationPushTransport {
  FirebasePushTransportService({
    FirebasePushTransportForegroundPresentationSetter? configureForegroundPresentation,
    FirebasePushTransportBackgroundRegistrar? backgroundHandlerRegistrar,
    Stream<RemoteMessage>? foregroundRemoteMessages,
    Stream<RemoteMessage>? openedRemoteMessages,
    FirebasePushTransportInitialMessageGetter? initialMessageGetter,
    FirebasePushTransportTokenGetter? tokenGetter,
    Stream<String>? tokenRefreshEvents,
    FirebasePushTransportNotificationSettingsGetter? notificationSettingsGetter,
    FirebasePushTransportPermissionRequester? permissionRequester,
  }) : _configureForegroundPresentation = configureForegroundPresentation,
       _backgroundHandlerRegistrar = backgroundHandlerRegistrar,
       _foregroundMessageStream = foregroundRemoteMessages,
       _openedMessageStream = openedRemoteMessages,
       _getInitialMessage = initialMessageGetter,
       _getToken = tokenGetter,
       _tokenRefreshStream = tokenRefreshEvents,
       _getNotificationSettings = notificationSettingsGetter,
       _requestPermission = permissionRequester;

  final FirebasePushTransportForegroundPresentationSetter? _configureForegroundPresentation;
  final FirebasePushTransportBackgroundRegistrar? _backgroundHandlerRegistrar;
  final Stream<RemoteMessage>? _foregroundMessageStream;
  final Stream<RemoteMessage>? _openedMessageStream;
  final FirebasePushTransportInitialMessageGetter? _getInitialMessage;
  final FirebasePushTransportTokenGetter? _getToken;
  final Stream<String>? _tokenRefreshStream;
  final FirebasePushTransportNotificationSettingsGetter? _getNotificationSettings;
  final FirebasePushTransportPermissionRequester? _requestPermission;

  @override
  Stream<TransportRemoteMessage> get foregroundMessages =>
      (_foregroundMessageStream ?? FirebaseMessaging.onMessage).map(_mapRemoteMessage);

  @override
  Stream<TransportRemoteMessage> get openedMessages =>
      (_openedMessageStream ?? FirebaseMessaging.onMessageOpenedApp).map(_mapRemoteMessage);

  @override
  Future<void> configureForegroundPresentation() {
    LogDev.data('[FirebasePushTransportService] configureForegroundPresentation');
    return (_configureForegroundPresentation ?? _defaultFirebasePushTransportConfigureForegroundPresentation)(
      false,
      true,
      false,
    );
  }

  @override
  Future<void> registerBackgroundHandler() async {
    LogDev.data('[FirebasePushTransportService] registerBackgroundHandler');
    (_backgroundHandlerRegistrar ?? FirebaseMessaging.onBackgroundMessage)(firebaseMessagingBackgroundHandler);
  }

  @override
  Future<TransportRemoteMessage?> getInitialMessage() async {
    final initialMessage = await (_getInitialMessage ?? _defaultFirebasePushTransportGetInitialMessage)();
    if (initialMessage == null) {
      LogDev.data('[FirebasePushTransportService] getInitialMessage: none');
      return null;
    }
    LogDev.data('[FirebasePushTransportService] getInitialMessage: messageId=${initialMessage.messageId}');
    return _mapRemoteMessage(initialMessage);
  }

  @override
  Future<String?> getToken() async {
    final token = await (_getToken ?? _defaultFirebasePushTransportGetToken)();
    LogDev.data('[FirebasePushTransportService] \r\ngetToken: hasToken=${token?.isNotEmpty ?? false} \r\ntoken=$token');
    return token;
  }

  @override
  Stream<String> get tokenRefreshStream => _tokenRefreshStream ?? _defaultFirebasePushTransportTokenRefreshStream();

  @override
  Future<NotificationPermissionStatus> getPermissionStatus() async {
    final settings = await (_getNotificationSettings ?? _defaultFirebasePushTransportGetNotificationSettings)();
    LogDev.data('[FirebasePushTransportService] getPermissionStatus: ${settings.authorizationStatus}');
    return _mapAuthorizationStatus(settings.authorizationStatus);
  }

  @override
  Future<NotificationPermissionStatus> requestPermission() async {
    LogDev.data('[FirebasePushTransportService] requestPermission');
    final settings = await (_requestPermission ?? _defaultFirebasePushTransportRequestPermission)(
      true,
      true,
      true,
      false,
      false,
      false,
      false,
      false,
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
      hasNotificationPayload: message.notification != null,
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
    await _firebasePushTransportInitializeApp();

    final router = _firebasePushTransportMessageRouterFactory();
    final localNotifications = _firebasePushTransportLocalNotificationsFactory();
    final payload = router.fromRemoteMessage(
      FirebasePushTransportService._mapRemoteMessage(message),
      config: const NotificationCoreConfig(),
    );

    if (!payload.hasVisibleContent) {
      LogDev.data('[FirebasePushTransportService] background message skipped: no visible content');
      return;
    }

    if (message.notification != null) {
      LogDev.data('[FirebasePushTransportService] background message skipped: system notification payload already handled');
      return;
    }

    await localNotifications.show(router.toLocalRequest(payload));
    LogDev.info('[FirebasePushTransportService] background local notification rendered');
  } catch (error, stackTrace) {
    LogDev.error('[FirebasePushTransportService] background handler failed: $error\n$stackTrace');
  }
}
