part of '../services.dart';

class NotificationService {
  factory NotificationService({
    NotificationPushTransport? pushTransport,
    NotificationLocalNotifications? localNotifications,
    NotificationMessageRouter? messageRouter,
    NotificationInteractionService? interactionService,
    NotificationTokenService? tokenService,
    NotificationForegroundPolicy? foregroundPolicy,
    NotificationPermissionService? permissionService,
    NotificationScheduleService? scheduleService,
    NotificationBootstrapService? bootstrapService,
  }) {
    final resolvedPushTransport = pushTransport ?? FirebasePushTransportService();
    final resolvedLocalNotifications = localNotifications ?? AwesomeLocalNotificationService();
    final resolvedMessageRouter = messageRouter ?? const NotificationMessageRouter();
    final resolvedInteractionService = interactionService ?? NotificationInteractionService();
    final resolvedTokenService = tokenService ?? NotificationTokenService();
    final resolvedForegroundPolicy = foregroundPolicy ?? const NotificationForegroundPolicy();
    final resolvedPermissionService =
        permissionService ??
        NotificationPermissionService(
          pushPermissionProvider: resolvedPushTransport,
          localPermissionProvider: resolvedLocalNotifications,
        );
    final resolvedScheduleService = scheduleService ?? NotificationScheduleService(resolvedLocalNotifications);
    final resolvedBootstrapService =
        bootstrapService ??
        NotificationBootstrapService(
          pushTransport: resolvedPushTransport,
          localNotifications: resolvedLocalNotifications,
          messageRouter: resolvedMessageRouter,
          interactionService: resolvedInteractionService,
          tokenService: resolvedTokenService,
          foregroundPolicy: resolvedForegroundPolicy,
          permissionService: resolvedPermissionService,
        );

    return NotificationService._(
      pushTransport: resolvedPushTransport,
      localNotifications: resolvedLocalNotifications,
      interactionService: resolvedInteractionService,
      tokenService: resolvedTokenService,
      permissionService: resolvedPermissionService,
      scheduleService: resolvedScheduleService,
      bootstrapService: resolvedBootstrapService,
    );
  }

  NotificationService._({
    required NotificationPushTransport pushTransport,
    required NotificationLocalNotifications localNotifications,
    required NotificationInteractionService interactionService,
    required NotificationTokenService tokenService,
    required NotificationPermissionService permissionService,
    required NotificationScheduleService scheduleService,
    required NotificationBootstrapService bootstrapService,
  }) : _pushTransport = pushTransport,
       _localNotifications = localNotifications,
       _interactionService = interactionService,
       _tokenService = tokenService,
       _permissionService = permissionService,
       _scheduleService = scheduleService,
       _bootstrapService = bootstrapService;

  final NotificationPushTransport _pushTransport;
  final NotificationLocalNotifications _localNotifications;
  final NotificationInteractionService _interactionService;
  final NotificationTokenService _tokenService;
  final NotificationPermissionService _permissionService;
  final NotificationScheduleService _scheduleService;
  final NotificationBootstrapService _bootstrapService;

  NotificationCoreConfig _config = const NotificationCoreConfig();

  static final NotificationService _instance = NotificationService();

  static Future<void> initialize(NotificationCoreConfig config) => _instance.initializeInternal(config);
  static Future<NotificationPermissionState> getPermissionState() => _instance.getPermissionStateInternal();
  static Future<NotificationPermissionState> requestPermission() => _instance.requestPermissionInternal();
  static Future<void> openSettings() => _instance.openSettingsInternal();
  static Future<String?> getToken() => _instance.getTokenInternal();
  static Stream<NotificationTokenState> get tokenRefreshStream => _instance.tokenRefreshStreamInternal;
  static Stream<NotificationInteraction> get interactionStream => _instance.interactionStreamInternal;
  static Future<void> showLocal(NotificationRequest request) => _instance.showLocalInternal(request);
  static Future<void> scheduleLocal(NotificationScheduleRequest request) => _instance.scheduleLocalInternal(request);
  static Future<void> cancel(int id) => _instance.cancelInternal(id);
  static Future<void> cancelAll() => _instance.cancelAllInternal();

  Stream<NotificationTokenState> get tokenRefreshStreamInternal => _tokenService.stream;
  Stream<NotificationInteraction> get interactionStreamInternal => _interactionService.stream;

  Future<void> initializeInternal(NotificationCoreConfig config) async {
    LogDev.info(
      '[NotificationService] initialize: '
      'push=${config.enablePush}, local=${config.enableLocal}, autoRequest=${config.autoRequestPermissionOnInit}',
    );
    _config = config;
    _interactionService.updateConfig(config);
    _tokenService.updateConfig(config);
    await _bootstrapService.initialize(config: config);
    LogDev.info('[NotificationService] initialize completed');
  }

  Future<NotificationPermissionState> getPermissionStateInternal() {
    return _permissionService.getPermissionState(
      enablePush: _config.enablePush,
      enableLocal: _config.enableLocal,
    );
  }

  Future<NotificationPermissionState> requestPermissionInternal() {
    return _permissionService.requestPermission(
      enablePush: _config.enablePush,
      enableLocal: _config.enableLocal,
    );
  }

  Future<void> openSettingsInternal() => _permissionService.openSettings();

  Future<String?> getTokenInternal() async {
    if (!_config.enablePush) {
      LogDev.warning('[NotificationService] getToken skipped because push is disabled');
      return null;
    }
    final token = _tokenService.currentToken ?? await _pushTransport.getToken();
    LogDev.data('[NotificationService] getToken resolved: hasToken=${token?.isNotEmpty ?? false}');
    return token;
  }

  Future<void> showLocalInternal(NotificationRequest request) async {
    if (!_config.enableLocal) {
      LogDev.warning('[NotificationService] showLocal skipped because local notifications are disabled');
      return;
    }
    LogDev.data('[NotificationService] showLocal: title="${request.title}" id=${request.id}');
    await _localNotifications.show(request);
  }

  Future<void> scheduleLocalInternal(NotificationScheduleRequest request) async {
    if (!_config.enableLocal) {
      LogDev.warning('[NotificationService] scheduleLocal skipped because local notifications are disabled');
      return;
    }
    LogDev.data(
      '[NotificationService] scheduleLocal: '
      'id=${request.notification.id} title="${request.notification.title}" '
      'scheduledAt=${request.scheduledAt} interval=${request.interval} repeats=${request.repeats}',
    );
    await _scheduleService.schedule(request);
  }

  Future<void> cancelInternal(int id) {
    LogDev.data('[NotificationService] cancel: id=$id');
    return _scheduleService.cancel(id);
  }

  Future<void> cancelAllInternal() {
    LogDev.data('[NotificationService] cancelAll');
    return _scheduleService.cancelAll();
  }

  @visibleForTesting
  Future<void> dispose() async {
    LogDev.data('[NotificationService] dispose');
    await _bootstrapService.dispose();
    await _interactionService.dispose();
    await _tokenService.dispose();
    await _localNotifications.dispose();
  }
}
