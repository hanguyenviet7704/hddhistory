part of '../../services.dart';

class NotificationBootstrapService {
  NotificationBootstrapService({
    required NotificationPushTransport pushTransport,
    required NotificationLocalNotifications localNotifications,
    required NotificationMessageRouter messageRouter,
    required NotificationInteractionService interactionService,
    required NotificationTokenService tokenService,
    required NotificationForegroundPolicy foregroundPolicy,
    required NotificationPermissionService permissionService,
  }) : _pushTransport = pushTransport,
       _localNotifications = localNotifications,
       _messageRouter = messageRouter,
       _interactionService = interactionService,
       _tokenService = tokenService,
       _foregroundPolicy = foregroundPolicy,
       _permissionService = permissionService;

  final NotificationPushTransport _pushTransport;
  final NotificationLocalNotifications _localNotifications;
  final NotificationMessageRouter _messageRouter;
  final NotificationInteractionService _interactionService;
  final NotificationTokenService _tokenService;
  final NotificationForegroundPolicy _foregroundPolicy;
  final NotificationPermissionService _permissionService;

  StreamSubscription<TransportRemoteMessage>? _foregroundSubscription;
  StreamSubscription<TransportRemoteMessage>? _openedSubscription;
  StreamSubscription<TransportLocalAction>? _localActionSubscription;

  NotificationCoreConfig _config = const NotificationCoreConfig();
  bool _pushInitialized = false;
  bool _localInitialized = false;
  bool _initialInteractionRestored = false;

  Future<void> initialize({
    required NotificationCoreConfig config,
  }) async {
    _config = config;
    _interactionService.updateConfig(_config);
    _tokenService.updateConfig(_config);

    if (_config.enableLocal && !_localInitialized) {
      await _localNotifications.initialize();
      await _localNotifications.registerListeners();
      _localActionSubscription = _localNotifications.actionStream.listen((action) {
        unawaited(_publishLocalInteraction(action));
      });
      _localInitialized = true;
    }

    if (_config.enablePush && !_pushInitialized) {
      await _pushTransport.configureForegroundPresentation();
      await _pushTransport.registerBackgroundHandler();

      _foregroundSubscription = _pushTransport.foregroundMessages.listen((message) {
        unawaited(_handleForegroundMessage(message));
      });
      _openedSubscription = _pushTransport.openedMessages.listen((message) {
        unawaited(_publishRemoteInteraction(message, type: NotificationInteractionType.openedApp));
      });

      await _tokenService.syncInitialToken(_pushTransport.getToken);
      await _tokenService.bindRefreshStream(_pushTransport.tokenRefreshStream);
      _pushInitialized = true;
    }

    if (_config.autoRequestPermissionOnInit) {
      await _permissionService.requestPermission(
        enablePush: _config.enablePush,
        enableLocal: _config.enableLocal,
      );
    }

    if (!_initialInteractionRestored && (_config.enablePush || _config.enableLocal)) {
      await _restoreInitialInteraction();
      _initialInteractionRestored = true;
    }
  }

  Future<void> dispose() async {
    await _foregroundSubscription?.cancel();
    await _openedSubscription?.cancel();
    await _localActionSubscription?.cancel();
  }

  Future<void> _handleForegroundMessage(
    TransportRemoteMessage message,
  ) async {
    final payload = _messageRouter.fromRemoteMessage(message, config: _config);
    await _interactionService.publish(
      NotificationInteraction(
        type: NotificationInteractionType.foregroundReceived,
        payload: payload,
        occurredAt: DateTime.now(),
      ),
    );

    if (_foregroundPolicy.shouldRender(payload: payload, config: _config)) {
      await _localNotifications.show(_messageRouter.toLocalRequest(payload));
    }
  }

  Future<void> _publishRemoteInteraction(
    TransportRemoteMessage message, {
    required NotificationInteractionType type,
  }) {
    final payload = _messageRouter.fromRemoteMessage(message, config: _config);
    return _interactionService.publish(
      NotificationInteraction(
        type: type,
        payload: payload,
        occurredAt: DateTime.now(),
      ),
    );
  }

  Future<void> _publishLocalInteraction(
    TransportLocalAction action,
  ) {
    final payload = _messageRouter.fromLocalAction(action, config: _config);
    final type = action.fromTerminated
        ? NotificationInteractionType.coldStart
        : action.fromBackground
        ? NotificationInteractionType.openedApp
        : NotificationInteractionType.localAction;

    return _interactionService.publish(
      NotificationInteraction(
        type: type,
        payload: payload,
        occurredAt: action.performedAt,
        actionKey: action.actionKey,
        inputText: action.inputText,
      ),
    );
  }

  Future<void> _restoreInitialInteraction() async {
    if (_config.enablePush) {
      final initialRemoteMessage = await _pushTransport.getInitialMessage();
      if (initialRemoteMessage != null) {
        await _publishRemoteInteraction(
          initialRemoteMessage,
          type: NotificationInteractionType.coldStart,
        );
        return;
      }
    }

    if (_config.enableLocal) {
      final initialLocalAction = await _localNotifications.getInitialAction();
      if (initialLocalAction != null) {
        await _publishLocalInteraction(initialLocalAction);
      }
    }
  }
}
