part of '../../learning_streak.dart';

/// Decides when the streak popup may appear, based on how long the user has
/// had the app in the foreground **today**.
///
/// Replaces the old "just finished a keypoint" trigger
/// ([LearningStreakCompletionGate]), which only ever fired for people already
/// deep in a lesson — the users who least needed a nudge.
///
/// Time is accumulated across sessions rather than measured per session: six
/// twenty-second visits show as much intent as one two-minute sit, and a
/// per-session timer would never fire for the first kind of user at all.
///
/// The counter is keyed by UTC day to match
/// [LearningStreakCubit.isSameStreakCountedUtcDay], which owns the
/// once-per-day rule. Two different day definitions would let the popup fire
/// twice around midnight.
class StreakPopupScheduler with WidgetsBindingObserver {
  StreakPopupScheduler(this._localStore);

  static const String _secondsKeyPrefix = 'streak_popup_seconds';
  static const String _dayKey = 'streak_popup_day';

  /// Ticks often enough that the popup lands close to the configured mark
  /// without waking the app up constantly.
  static const Duration _tick = Duration(seconds: 10);

  final ILocalStoreService _localStore;

  Timer? _timer;
  DateTime? _foregroundSince;
  bool _started = false;

  /// Called when the threshold is crossed. Set by whoever mounts the
  /// scheduler; the scheduler itself knows nothing about widgets.
  Future<void> Function()? onThresholdReached;

  StreakPopupConfigEntity _config = const StreakPopupConfigEntity();

  StreakPopupConfigEntity get config => _config;

  void updateConfig(StreakPopupConfigEntity value) => _config = value;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _foregroundSince = DateTime.now();
    await _rolloverIfNewDay();
    _timer = Timer.periodic(_tick, (_) => unawaited(_onTick()));
  }

  Future<void> dispose() async {
    if (!_started) return;
    _started = false;
    _timer?.cancel();
    _timer = null;
    WidgetsBinding.instance.removeObserver(this);
    await _flush();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _foregroundSince = DateTime.now();
      unawaited(_rolloverIfNewDay());
      return;
    }
    // Banking the elapsed time on the way out is what makes the total survive
    // being backgrounded — without it, anyone who leaves before the tick would
    // lose the whole interval.
    unawaited(_flush());
  }

  Future<void> _onTick() async {
    await _flush();
    if (!_config.popupEnabled) return;

    final seconds = await _readSeconds();
    if (seconds < _config.triggerAfterSeconds) return;

    final callback = onThresholdReached;
    if (callback == null) return;
    await callback();
  }

  /// Moves the time banked since the last flush into the stored total.
  Future<void> _flush() async {
    final since = _foregroundSince;
    if (since == null) return;
    final now = DateTime.now();
    _foregroundSince = now;

    final elapsed = now.difference(since).inSeconds;
    // A negative or absurd delta means the device clock moved (timezone
    // change, manual adjustment, NTP correction). Drop it rather than let it
    // poison the running total in either direction.
    if (elapsed <= 0 || elapsed > 3600) return;

    if (await _rolloverIfNewDay()) return;

    final current = await _readSeconds();
    await _localStore.setInt(key: _secondsKey(), value: current + elapsed);
  }

  /// Resets the counter when the UTC day changes. Returns true when it did.
  Future<bool> _rolloverIfNewDay() async {
    final today = _utcDayKey(DateTime.now());
    final stored = await _localStore.getString(key: _dayKey);
    if (stored == today) return false;

    await _localStore.setString(key: _dayKey, value: today);
    await _localStore.setInt(key: _secondsKey(), value: 0);
    return true;
  }

  Future<int> _readSeconds() async {
    try {
      return await _localStore.getInt(key: _secondsKey());
    } catch (_) {
      return 0;
    }
  }

  String _secondsKey() => '${_secondsKeyPrefix}_${_utcDayKey(DateTime.now())}';

  static String _utcDayKey(DateTime value) {
    final utc = value.toUtc();
    return '${utc.year}-${utc.month.toString().padLeft(2, '0')}-'
        '${utc.day.toString().padLeft(2, '0')}';
  }
}
