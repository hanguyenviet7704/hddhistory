part of '../services.dart';

/// Mirrors every fired tracking event to hddhistory-api so the admin panel can read a
/// user's behaviour timeline (`POST /api/v1/analytics/events`).
///
/// Sits beside [FirebaseAnalyticsService] inside the composite bound to
/// [DIKey.trackingService], so it picks up all ~442 events plus every future one
/// without touching a single call site.
///
/// Rules that matter:
/// - `userId` is derived server-side from the request token, so the queue MUST be
///   flushed BEFORE the user changes ([setUserId] / [resetUser] do that) or one
///   user's events land on another.
/// - Everything here is fire-and-forget. A tracking failure must never surface in
///   the UI, so all paths swallow errors.
class BackendTrackingService extends BaseTrackingService {
  BackendTrackingService()
    : super(
        trackingServiceName: 'BackendTrackingService',
        isEnabled: true,
      );

  /// GA4's own convention: a gap this long starts a new session.
  static const Duration _sessionGap = Duration(minutes: 30);
  static const Duration _flushInterval = Duration(seconds: 15);
  static const int _flushThreshold = 20;

  /// Per-request cap enforced by the api. Also the batch size we send.
  static const int _maxBatchSize = 200;

  /// Queue ceiling. When full the OLDEST event is dropped — recent behaviour is
  /// the part anyone actually looks at.
  static const int _maxQueueSize = 2000;

  final Queue<Map<String, dynamic>> _queue = Queue<Map<String, dynamic>>();
  final Uuid _uuid = const Uuid();

  Timer? _flushTimer;
  AppLifecycleListener? _lifecycleListener;
  bool _flushing = false;
  String? _sessionId;
  DateTime? _lastEventAt;

  @override
  Future<void> initialize() async {
    if (!isEnabled) return;

    await _restoreQueue();

    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(_flushInterval, (_) => unawaited(_flush()));

    // Flush on the way to the background: that is the moment a session usually
    // ends, and the process may not come back.
    _lifecycleListener?.dispose();
    _lifecycleListener = AppLifecycleListener(
      onPause: () => unawaited(_flush()),
      onDetach: () => unawaited(_persistQueue()),
    );

    super.initialize();
  }

  @override
  Future<void> trackEvent(String eventName, {Map<String, dynamic>? parameters}) async {
    if (!isEnabled) return;
    _enqueue(eventName, parameters, 'event');
  }

  @override
  Future<void> trackScreenView(String screenName, {String? screenClass}) async {
    if (!isEnabled) return;
    _enqueue(
      screenName,
      screenClass == null ? null : {'screen_class': screenClass},
      'screen',
    );
  }

  @override
  Future<void> setUserId(String? userId) async {
    if (!isEnabled) return;
    await _flushBeforeUserSwitch();
    if (userId == null) _sessionId = null;
  }

  @override
  Future<void> resetUser() async {
    if (!isEnabled) return;
    await _flushBeforeUserSwitch();
    _sessionId = null;
  }

  /// Flush with the token still in force, then DROP whatever could not be sent.
  /// Anything left would go out under the next user's token and be filed against
  /// the wrong person — losing the last few events of a session is the cheaper
  /// mistake.
  Future<void> _flushBeforeUserSwitch() async {
    await _flush();
    if (_queue.isNotEmpty) {
      _queue.clear();
      unawaited(_persistQueue());
    }
  }

  @override
  Future<void> setTrackingEnabled(bool isEnabled) async {
    if (!isEnabled) {
      _flushTimer?.cancel();
      _flushTimer = null;
      _queue.clear();
    }
    super.setTrackingEnabled(isEnabled);
  }

  void _enqueue(String name, Map<String, dynamic>? parameters, String kind) {
    if (name.trim().isEmpty) return;

    final DateTime now = DateTime.now();
    _queue.add({
      'name': name,
      'kind': kind,
      'sessionId': _resolveSessionId(now),
      'clientTs': now.millisecondsSinceEpoch,
      if (parameters != null && parameters.isNotEmpty) 'params': _sanitize(parameters),
    });
    _lastEventAt = now;

    while (_queue.length > _maxQueueSize) {
      _queue.removeFirst();
    }

    if (_queue.length >= _flushThreshold) unawaited(_flush());
  }

  String _resolveSessionId(DateTime now) {
    final DateTime? last = _lastEventAt;
    if (_sessionId == null || last == null || now.difference(last) > _sessionGap) {
      _sessionId = _uuid.v4();
    }
    return _sessionId!;
  }

  /// Params come from ~442 call sites; keep only JSON-encodable leaves so one odd
  /// value can't make the whole batch unencodable.
  Map<String, dynamic> _sanitize(Map<String, dynamic> parameters) {
    final Map<String, dynamic> clean = {};
    parameters.forEach((key, value) {
      if (value == null) return;
      if (value is num || value is bool || value is String) {
        clean[key] = value;
      } else if (value is Iterable) {
        clean[key] = value.map((e) => e is num || e is bool || e is String ? e : e.toString()).toList();
      } else if (value is DateTime) {
        clean[key] = value.toIso8601String();
      } else {
        clean[key] = value.toString();
      }
    });
    return clean;
  }

  Future<void> _flush() async {
    if (!isEnabled || _flushing || _queue.isEmpty) return;

    // Never post without a token. Two reasons, both load-bearing:
    // 1. The api derives userId from the token, so an anonymous post is useless.
    // 2. AppInterceptor turns a 401 into clear-session + "session expired" toast
    //    + a jump to the welcome screen. A background tracking call must never be
    //    able to log the user out.
    // Events fired before loginAnonymous simply wait here and go out with the
    // first batch after the token exists — same user, correct owner.
    if (AppGlobalValue.accessToken.isEmpty) return;

    _flushing = true;

    final List<Map<String, dynamic>> batch = [];
    while (_queue.isNotEmpty && batch.length < _maxBatchSize) {
      batch.add(_queue.removeFirst());
    }

    try {
      final Dio dio = AppDI.injector.get<Dio>(instanceName: DIKey.appDio);
      final IDeviceInfoService deviceInfo = AppDI.injector.get<IDeviceInfoService>();
      final PackageInfo packageInfo = AppDI.injector.get<IPackageInfoService>().packageInfo;

      await dio.post(
        AppEndpoint.analyticsEvents,
        data: {
          'deviceId': await deviceInfo.deviceToken,
          'appEnv': EnvConstant.appEnv,
          'appVersion': packageInfo.version,
          'platform': Platform.isIOS ? 'ios' : 'android',
          'events': batch,
        },
      );
    } catch (_) {
      // Offline / 401 / server down: put the batch back at the FRONT so order
      // survives, and persist so a kill doesn't lose it.
      for (final Map<String, dynamic> event in batch.reversed) {
        _queue.addFirst(event);
      }
      while (_queue.length > _maxQueueSize) {
        _queue.removeFirst();
      }
      unawaited(_persistQueue());
    } finally {
      _flushing = false;
    }
  }

  Future<void> _persistQueue() async {
    try {
      final ILocalStoreService store = AppDI.injector.get<ILocalStoreService>();
      if (_queue.isEmpty) {
        await store.remove(key: LocalStoreKey.trackingEventQueue);
        return;
      }
      await store.setString(
        key: LocalStoreKey.trackingEventQueue,
        value: jsonEncode(_queue.toList()),
      );
    } catch (_) {
      // Nothing to do — losing the persisted copy is not worth reporting.
    }
  }

  Future<void> _restoreQueue() async {
    try {
      final ILocalStoreService store = AppDI.injector.get<ILocalStoreService>();
      final String raw = await store.getString(key: LocalStoreKey.trackingEventQueue);
      if (raw.isEmpty) return;

      final dynamic decoded = jsonDecode(raw);
      if (decoded is! List) return;

      for (final dynamic event in decoded) {
        if (event is Map<String, dynamic>) _queue.add(event);
      }
      while (_queue.length > _maxQueueSize) {
        _queue.removeFirst();
      }
      await store.remove(key: LocalStoreKey.trackingEventQueue);
    } catch (_) {
      // Corrupt payload: drop it rather than block startup.
    }
  }
}
