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
    LogDev.info(
      '[NotificationBootstrapService] initialize: '
      'push=${config.enablePush}, local=${config.enableLocal}, autoRequest=${config.autoRequestPermissionOnInit}',
    );
    _config = config;
    _interactionService.updateConfig(_config);
    _tokenService.updateConfig(_config);

    if (_config.enableLocal && !_localInitialized) {
      LogDev.data('[NotificationBootstrapService] initializing local notifications');
      await _localNotifications.initialize();
      await _localNotifications.registerListeners();
      _localActionSubscription = _localNotifications.actionStream.listen((action) {
        unawaited(_publishLocalInteraction(action));
      });
      _localInitialized = true;
      LogDev.info('[NotificationBootstrapService] local notifications initialized');
    }

    if (_config.enablePush && !_pushInitialized) {
      LogDev.data('[NotificationBootstrapService] initializing push transport');
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
      LogDev.info('[NotificationBootstrapService] push transport initialized');
    }

    if (_config.autoRequestPermissionOnInit) {
      LogDev.data('[NotificationBootstrapService] requesting permission during initialize');
      await _permissionService.requestPermission(
        enablePush: _config.enablePush,
        enableLocal: _config.enableLocal,
      );
    }

    if (!_initialInteractionRestored && (_config.enablePush || _config.enableLocal)) {
      LogDev.data('[NotificationBootstrapService] restoring initial interaction');
      await _restoreInitialInteraction();
      _initialInteractionRestored = true;
    }

    LogDev.info('[NotificationBootstrapService] initialize completed');
  }

  Future<void> dispose() async {
    LogDev.data('[NotificationBootstrapService] dispose');
    await _foregroundSubscription?.cancel();
    await _openedSubscription?.cancel();
    await _localActionSubscription?.cancel();
  }

  Future<void> _handleForegroundMessage(
    TransportRemoteMessage message,
  ) async {
    LogDev.data(
      '[NotificationBootstrapService] foreground message: '
      'messageId=${message.messageId} title="${message.title ?? ''}"',
    );
    final payload = _messageRouter.fromRemoteMessage(message, config: _config);
    await _interactionService.publish(
      NotificationInteraction(
        type: NotificationInteractionType.foregroundReceived,
        payload: payload,
        occurredAt: DateTime.now(),
      ),
    );

    if (_foregroundPolicy.shouldRender(payload: payload, config: _config)) {
      LogDev.data('[NotificationBootstrapService] rendering foreground message as local notification');
      await _localNotifications.show(_messageRouter.toLocalRequest(payload));
    } else {
      LogDev.data('[NotificationBootstrapService] foreground render skipped by policy');
    }
  }

  Future<void> _publishRemoteInteraction(
    TransportRemoteMessage message, {
    required NotificationInteractionType type,
  }) {
    LogDev.data(
      '[NotificationBootstrapService] publish remote interaction: '
      'type=$type messageId=${message.messageId}',
    );
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
    LogDev.data(
      '[NotificationBootstrapService] publish local interaction: '
      'id=${action.id} actionKey=${action.actionKey} '
      'background=${action.fromBackground} terminated=${action.fromTerminated}',
    );
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
        LogDev.info(
          '[NotificationBootstrapService] restored cold-start remote interaction: '
          'messageId=${initialRemoteMessage.messageId}',
        );
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
        LogDev.info(
          '[NotificationBootstrapService] restored cold-start local interaction: '
          'id=${initialLocalAction.id}',
        );
        await _publishLocalInteraction(initialLocalAction);
      }
    }
  }
}
