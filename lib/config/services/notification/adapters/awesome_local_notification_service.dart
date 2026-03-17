part of '../../services.dart';

const String _notificationActionPortName = 'meup.notification.action.port';

ReceivePort? _notificationActionReceivePort;
AwesomeLocalNotificationService? _notificationActionService;

@pragma('vm:entry-point')
Future<void> awesomeLocalNotificationActionEntryPoint(ReceivedAction receivedAction) async {
  WidgetsFlutterBinding.ensureInitialized();

  final localService = _notificationActionService;
  if (localService != null) {
    await localService._handleActionReceived(receivedAction);
    return;
  }

  final sendPort = ui.IsolateNameServer.lookupPortByName(_notificationActionPortName);
  if (sendPort == null) {
    LogDev.warning('[AwesomeLocalNotificationService] action dropped because main isolate port is unavailable');
    return;
  }

  sendPort.send(receivedAction.toMap());
}

void _bindNotificationActionPort(AwesomeLocalNotificationService service) {
  _notificationActionService = service;
  if (_notificationActionReceivePort != null) {
    return;
  }

  final receivePort = ReceivePort();
  ui.IsolateNameServer.removePortNameMapping(_notificationActionPortName);
  final isRegistered = ui.IsolateNameServer.registerPortWithName(
    receivePort.sendPort,
    _notificationActionPortName,
  );

  if (!isRegistered) {
    receivePort.close();
    LogDev.warning('[AwesomeLocalNotificationService] failed to register action port');
    return;
  }

  receivePort.listen((dynamic message) async {
    if (message is! Map) {
      LogDev.warning('[AwesomeLocalNotificationService] ignored action payload with unsupported type');
      return;
    }

    final action = ReceivedAction().fromMap(Map<String, dynamic>.from(message));
    await _notificationActionService?._handleActionReceived(action);
  });

  _notificationActionReceivePort = receivePort;
}

void _unbindNotificationActionPort(AwesomeLocalNotificationService service) {
  if (!identical(_notificationActionService, service)) {
    return;
  }

  _notificationActionService = null;
  _notificationActionReceivePort?.close();
  _notificationActionReceivePort = null;
  ui.IsolateNameServer.removePortNameMapping(_notificationActionPortName);
}

abstract interface class NotificationLocalNotifications implements NotificationLocalPermissionProvider {
  Future<void> initialize();
  Future<void> registerListeners();
  Stream<TransportLocalAction> get actionStream;
  Future<TransportLocalAction?> getInitialAction();
  Future<void> show(NotificationRequest request);
  Future<void> schedule(NotificationScheduleRequest request);
  Future<void> cancel(int id);
  Future<void> cancelSchedule(int id);
  Future<void> cancelAll();
  Future<void> cancelAllSchedules();
  Future<void> dispose();
}

abstract class AwesomeLocalNotificationsGateway {
  Future<bool> initialize(
    String? defaultIcon,
    List<NotificationChannel> channels, {
    List<NotificationChannelGroup>? channelGroups,
    bool debug,
  });
  Future<bool> setListeners({
    required ActionHandler onActionReceivedMethod,
    NotificationHandler? onNotificationCreatedMethod,
    NotificationHandler? onNotificationDisplayedMethod,
    ActionHandler? onDismissActionReceivedMethod,
  });
  Future<ReceivedAction?> getInitialNotificationAction({
    bool removeFromActionEvents = false,
  });
  Future<String> getLocalTimeZoneIdentifier();
  Future<bool> createNotification({
    required NotificationContent content,
    NotificationSchedule? schedule,
  });
  Future<void> cancel(int id);
  Future<void> cancelAll();
  Future<void> cancelSchedule(int id);
  Future<void> cancelAllSchedules();
  Future<bool> isNotificationAllowed();
  Future<bool> requestPermissionToSendNotifications();
}

class DefaultAwesomeLocalNotificationsGateway implements AwesomeLocalNotificationsGateway {
  final AwesomeNotifications _notifications = AwesomeNotifications();

  @override
  Future<void> cancel(int id) => _notifications.cancel(id);

  @override
  Future<void> cancelAll() => _notifications.cancelAll();

  @override
  Future<void> cancelAllSchedules() => _notifications.cancelAllSchedules();

  @override
  Future<void> cancelSchedule(int id) => _notifications.cancelSchedule(id);

  @override
  Future<bool> createNotification({
    required NotificationContent content,
    NotificationSchedule? schedule,
  }) {
    return _notifications.createNotification(
      content: content,
      schedule: schedule,
    );
  }

  @override
  Future<ReceivedAction?> getInitialNotificationAction({
    bool removeFromActionEvents = false,
  }) {
    return _notifications.getInitialNotificationAction(
      removeFromActionEvents: removeFromActionEvents,
    );
  }

  @override
  Future<String> getLocalTimeZoneIdentifier() => _notifications.getLocalTimeZoneIdentifier();

  @override
  Future<bool> initialize(
    String? defaultIcon,
    List<NotificationChannel> channels, {
    List<NotificationChannelGroup>? channelGroups,
    bool debug = false,
  }) {
    return _notifications.initialize(
      defaultIcon,
      channels,
      channelGroups: channelGroups,
      debug: debug,
    );
  }

  @override
  Future<bool> setListeners({
    required ActionHandler onActionReceivedMethod,
    NotificationHandler? onNotificationCreatedMethod,
    NotificationHandler? onNotificationDisplayedMethod,
    ActionHandler? onDismissActionReceivedMethod,
  }) {
    return _notifications.setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
      onNotificationCreatedMethod: onNotificationCreatedMethod,
      onNotificationDisplayedMethod: onNotificationDisplayedMethod,
      onDismissActionReceivedMethod: onDismissActionReceivedMethod,
    );
  }

  @override
  Future<bool> isNotificationAllowed() => _notifications.isNotificationAllowed();

  @override
  Future<bool> requestPermissionToSendNotifications() => _notifications.requestPermissionToSendNotifications();
}

class AwesomeLocalNotificationService implements NotificationLocalNotifications {
  AwesomeLocalNotificationService({
    AwesomeLocalNotificationsGateway? gateway,
    NotificationChannelConfig? channelConfig,
  }) : _gateway = gateway ?? DefaultAwesomeLocalNotificationsGateway(),
       _channelConfig = channelConfig ?? NotificationConstants.defaultChannel;

  final AwesomeLocalNotificationsGateway _gateway;
  final NotificationChannelConfig _channelConfig;
  Future<void>? _initializeFuture;
  Future<void>? _registerListenersFuture;
  final Queue<TransportLocalAction> _pendingActions = Queue<TransportLocalAction>();
  late final StreamController<TransportLocalAction> _actionController = StreamController<TransportLocalAction>.broadcast(
    sync: true,
    onListen: _flushPendingActions,
  );

  @override
  Stream<TransportLocalAction> get actionStream => _actionController.stream;

  @override
  Future<void> initialize() => _initializeFuture ??= _initialize();

  @override
  Future<void> registerListeners() => _registerListenersFuture ??= _registerListeners();

  @override
  Future<TransportLocalAction?> getInitialAction() async {
    final action = await _gateway.getInitialNotificationAction(removeFromActionEvents: true);
    if (action == null) {
      LogDev.data('[AwesomeLocalNotificationService] getInitialAction: none');
      return null;
    }
    LogDev.data('[AwesomeLocalNotificationService] getInitialAction: id=${action.id}');
    return _mapReceivedAction(action);
  }

  @override
  Future<void> show(NotificationRequest request) async {
    await initialize();
    LogDev.data('[AwesomeLocalNotificationService] show: id=${request.id} title="${request.title}"');
    await _gateway.createNotification(content: _buildContent(request));
  }

  @override
  Future<void> schedule(NotificationScheduleRequest request) async {
    await initialize();
    LogDev.data(
      '[AwesomeLocalNotificationService] schedule: '
      'id=${request.notification.id} scheduledAt=${request.scheduledAt} interval=${request.interval}',
    );
    await _gateway.createNotification(
      content: _buildContent(request.notification),
      schedule: await _buildSchedule(request),
    );
  }

  @override
  Future<void> cancel(int id) async {
    LogDev.data('[AwesomeLocalNotificationService] cancel: id=$id');
    await _gateway.cancel(id);
  }

  @override
  Future<void> cancelSchedule(int id) {
    LogDev.data('[AwesomeLocalNotificationService] cancelSchedule: id=$id');
    return _gateway.cancelSchedule(id);
  }

  @override
  Future<void> cancelAll() async {
    LogDev.data('[AwesomeLocalNotificationService] cancelAll');
    await _gateway.cancelAll();
  }

  @override
  Future<void> cancelAllSchedules() {
    LogDev.data('[AwesomeLocalNotificationService] cancelAllSchedules');
    return _gateway.cancelAllSchedules();
  }

  @override
  Future<bool> isPermissionGranted() async {
    final isGranted = await _gateway.isNotificationAllowed();
    LogDev.data('[AwesomeLocalNotificationService] isPermissionGranted: $isGranted');
    return isGranted;
  }

  @override
  Future<bool> requestPermission() async {
    LogDev.data('[AwesomeLocalNotificationService] requestPermission');
    final isGranted = await _gateway.requestPermissionToSendNotifications();
    LogDev.data('[AwesomeLocalNotificationService] requestPermission result: $isGranted');
    return isGranted;
  }

  @override
  Future<void> dispose() async {
    LogDev.data('[AwesomeLocalNotificationService] dispose');
    _unbindNotificationActionPort(this);
    await _actionController.close();
  }

  Future<void> _initialize() async {
    LogDev.data('[AwesomeLocalNotificationService] initialize');
    await _gateway.initialize(
      null,
      <NotificationChannel>[
        NotificationChannel(
          channelGroupKey: _channelConfig.channelGroupKey,
          channelKey: _channelConfig.channelKey,
          channelName: _channelConfig.channelName,
          channelDescription: _channelConfig.channelDescription,
          defaultColor: const Color(0xFF9D50DD),
          ledColor: Colors.white,
          importance: NotificationImportance.Max,
          channelShowBadge: true,
          onlyAlertOnce: true,
          playSound: true,
          criticalAlerts: true,
        ),
      ],
      channelGroups: <NotificationChannelGroup>[
        NotificationChannelGroup(
          channelGroupKey: _channelConfig.channelGroupKey,
          channelGroupName: _channelConfig.channelGroupName,
        ),
      ],
      debug: false,
    );
    LogDev.info('[AwesomeLocalNotificationService] initialize completed');
  }

  Future<void> _registerListeners() async {
    await initialize();
    LogDev.data('[AwesomeLocalNotificationService] registerListeners');
    _bindNotificationActionPort(this);
    await _gateway.setListeners(
      onActionReceivedMethod: awesomeLocalNotificationActionEntryPoint,
    );
  }

  NotificationContent _buildContent(NotificationRequest request) {
    return NotificationContent(
      id: request.id ?? DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      channelKey: _channelConfig.channelKey,
      title: request.title,
      body: request.body,
      summary: request.summary,
      bigPicture: request.imageUrl,
      payload: request.payload,
      actionType: ActionType.Default,
      notificationLayout: request.imageUrl == null ? NotificationLayout.Default : NotificationLayout.BigPicture,
    );
  }

  Future<NotificationSchedule> _buildSchedule(NotificationScheduleRequest request) async {
    if (request.scheduledAt != null) {
      return NotificationCalendar.fromDate(
        date: request.scheduledAt!,
        repeats: request.repeats,
        preciseAlarm: request.preciseAlarm,
      );
    }

    return NotificationInterval(
      interval: request.interval!,
      repeats: request.repeats,
      preciseAlarm: request.preciseAlarm,
      timeZone: await _gateway.getLocalTimeZoneIdentifier(),
    );
  }

  Future<void> _handleActionReceived(ReceivedAction action) async {
    if (_actionController.isClosed) {
      return;
    }
    final mappedAction = _mapReceivedAction(action);
    LogDev.data(
      '[AwesomeLocalNotificationService] action received: '
      'id=${action.id} button=${action.buttonKeyPressed} lifecycle=${action.actionLifeCycle}',
    );
    if (_actionController.hasListener) {
      _actionController.add(mappedAction);
      return;
    }

    LogDev.data('[AwesomeLocalNotificationService] queue action until listener is attached');
    _pendingActions.add(mappedAction);
  }

  void _flushPendingActions() {
    if (_actionController.hasListener && _pendingActions.isNotEmpty) {
      LogDev.data('[AwesomeLocalNotificationService] flush pending actions: count=${_pendingActions.length}');
    }

    while (_actionController.hasListener && _pendingActions.isNotEmpty) {
      _actionController.add(_pendingActions.removeFirst());
    }
  }

  TransportLocalAction _mapReceivedAction(ReceivedAction action) {
    final payload = <String, String>{};
    final rawPayload = action.payload ?? const <String, String?>{};

    for (final entry in rawPayload.entries) {
      if (entry.value != null) {
        payload[entry.key] = entry.value!;
      }
    }

    return TransportLocalAction(
      id: action.id ?? 0,
      title: action.title,
      body: action.body,
      payload: payload,
      actionKey: action.buttonKeyPressed.isEmpty ? null : action.buttonKeyPressed,
      inputText: action.buttonKeyInput.isEmpty ? null : action.buttonKeyInput,
      performedAt: action.actionDate ?? DateTime.now(),
      fromBackground: action.actionLifeCycle == NotificationLifeCycle.Background,
      fromTerminated: action.actionLifeCycle == NotificationLifeCycle.Terminated,
    );
  }
}
