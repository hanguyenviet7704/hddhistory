part of '../../learning_streak.dart';

/// Mounts [StreakPopupScheduler] for the lifetime of the shell and raises the
/// streak toast when the daily time threshold is crossed.
///
/// Lives on the shell rather than on Home so the clock keeps running while the
/// user is in Explore, Habit or Profile — the threshold is "time in the app",
/// not "time staring at Home".
class StreakPopupHost extends StatefulWidget {
  const StreakPopupHost({super.key, required this.child});

  final Widget child;

  @override
  State<StreakPopupHost> createState() => _StreakPopupHostState();
}

class _StreakPopupHostState extends State<StreakPopupHost> {
  late final StreakPopupScheduler _scheduler;
  bool _showing = false;

  @override
  void initState() {
    super.initState();
    _scheduler = StreakPopupScheduler(AppDI.injector.get<ILocalStoreService>())
      ..onThresholdReached = _maybeShow;
    unawaited(_scheduler.start());
    unawaited(_loadConfig());
  }

  @override
  void dispose() {
    unawaited(_scheduler.dispose());
    super.dispose();
  }

  Future<void> _loadConfig() async {
    final result = await AppDI.injector
        .get<GetStreakPopupConfigUseCase>()
        .call()
        .run();
    // On failure keep the built-in defaults rather than disabling the popup:
    // a config request that fails once should not silently switch the feature
    // off for that session.
    result.match(
      (error) => LogDev.warning('Streak popup config failed: $error'),
      _scheduler.updateConfig,
    );
  }

  Future<void> _maybeShow() async {
    if (_showing || !mounted) return;

    final streakCubit = AppDI.injector.get<LearningStreakCubit>();
    final todayUtc = LearningStreakCompletionGate.resolveGateUtcDay(
      DateTime.now().toUtc(),
    );
    // Once per day, sharing the very same guard the old completion trigger
    // used — so switching trigger cannot make the popup show twice in a day.
    // Một lần mỗi ngày, dùng chung đúng chốt mà trigger hoàn-thành-keypoint
    // cũ đã dùng — nên việc đổi trigger không thể khiến popup bung hai lần
    // trong cùng một ngày.
    if (streakCubit.isSameStreakCountedUtcDay(todayUtc)) {
      LogDev.info('Streak popup: đã hiện hôm nay, bỏ qua');
      return;
    }

    // Never interrupt a sheet or dialog the user is already dealing with.
    if (LearningStreakModalGuard.hasBlockingModal(context)) {
      LogDev.info('Streak popup: có modal khác đang mở, bỏ qua');
      return;
    }

    _showing = true;
    try {
      final userId = AppDI.injector.get<UserCubit>().state.user.id;
      final result = await streakCubit.loadUserLearningStreak(
        triggerSource: LearningStreakTriggerSource.homeChip,
        requestedUserId: userId,
      );
      if (!mounted) return;
      if (!result.isRemoteSuccessWithPositiveStreak) {
        LogDev.info('Streak popup: streak không dương hoặc gọi API hỏng, bỏ qua');
        return;
      }
      LogDev.info('Streak popup: mở toast (streak=${result.streak.currentStreak})');

      await StreakToastOverlay.show(
        context,
        streak: result.streak,
        autoHideAfter: _scheduler.config.autoHideAfter,
      );
      streakCubit.setLastStreakCountedDate(todayUtc);
    } catch (error) {
      LogDev.warning('Streak popup failed to open: $error');
    } finally {
      _showing = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
