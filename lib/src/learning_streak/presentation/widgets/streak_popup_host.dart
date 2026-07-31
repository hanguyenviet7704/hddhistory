part of '../../learning_streak.dart';

/// Mounts [StreakPopupScheduler] for the lifetime of the shell, and when the
/// daily time threshold is crossed does two things in order: records today as a
/// day the user showed up, then raises the streak toast.
///
/// That order is the whole point. Time in the app is now the ONLY thing that
/// counts a streak day, so the check-in must not be skipped by anything that
/// merely stops the toast — a dialog being open, or the admin's `popupEnabled`
/// kill switch. It also means the toast is drawn from a streak that already
/// includes today, so its flame over today's slot tells the truth; before, the
/// toast could congratulate a day the server had not counted.
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
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _scheduler = StreakPopupScheduler(AppDI.injector.get<ILocalStoreService>())..onThresholdReached = _maybeCheckInAndShow;
    unawaited(_scheduler.start());
    unawaited(_loadConfig());
  }

  @override
  void dispose() {
    unawaited(_scheduler.dispose());
    super.dispose();
  }

  Future<void> _loadConfig() async {
    final result = await AppDI.injector.get<GetStreakPopupConfigUseCase>().call().run();
    // On failure keep the built-in defaults rather than disabling the popup:
    // a config request that fails once should not silently switch the feature
    // off for that session.
    result.match(
      (error) => LogDev.warning('Streak popup config failed: $error'),
      _scheduler.updateConfig,
    );
  }

  Future<void> _maybeCheckInAndShow() async {
    if (_busy || !mounted) return;

    final streakCubit = AppDI.injector.get<LearningStreakCubit>();
    final today = StreakDay.today();

    // Nothing left to do today: the day is recorded AND the toast has been
    // shown. Checked together so the cheap case costs no work at all.
    if (streakCubit.isSameCheckInDay(today) && streakCubit.isSameStreakCountedDay(today)) {
      return;
    }

    _busy = true;
    try {
      final userId = AppDI.injector.get<UserCubit>().state.user.id;

      // 1. Record the day. Runs before every toast concern below, and its latch
      // is set only on success (inside the cubit), so a failed request is
      // retried on the next tick rather than costing the user their day.
      if (!streakCubit.isSameCheckInDay(today)) {
        final checkedIn = await streakCubit.checkIn(requestedUserId: userId);
        if (!checkedIn) {
          LogDev.info('Streak check-in: gọi API hỏng, sẽ thử lại ở tick sau');
          return;
        }
        LogDev.info('Streak check-in: đã tính ngày hôm nay');
      }
      if (!mounted) return;

      // 2. The toast is optional decoration on top of that. `popupEnabled` is
      // the admin's kill switch for it alone — the day above is already counted.
      if (!_scheduler.config.popupEnabled) return;
      if (streakCubit.isSameStreakCountedDay(today)) {
        LogDev.info('Streak popup: đã hiện hôm nay, bỏ qua');
        return;
      }
      // Never interrupt a sheet or dialog the user is already dealing with. The
      // day's toast ticket is deliberately NOT spent here, so it can still show
      // once the modal closes.
      if (LearningStreakModalGuard.hasBlockingModal(context)) {
        LogDev.info('Streak popup: có modal khác đang mở, bỏ qua');
        return;
      }

      final streak = streakCubit.state.selectedItem;
      if (streak.currentStreak <= 0) {
        LogDev.info('Streak popup: streak không dương, bỏ qua');
        return;
      }
      LogDev.info('Streak popup: mở toast (streak=${streak.currentStreak})');

      final didShow = await StreakToastOverlay.show(
        context,
        streak: streak,
        autoHideAfter: _scheduler.config.autoHideAfter,
      );
      // Chỉ tiêu "vé mỗi ngày" khi toast thực sự được chèn và hiện ra. Trước
      // đây dòng này chạy vô điều kiện, nên một lần show trả về sớm (không tìm
      // được overlay) vẫn đánh dấu là đã hiện — và vì cờ này được Hydrated lưu
      // xuống đĩa, cả ngày còn lại sẽ im lặng dù người dùng chưa thấy gì.
      if (!didShow) {
        LogDev.info('Streak popup: không chèn được toast, giữ lại lượt hôm nay');
        return;
      }
      streakCubit.setLastStreakCountedDate(today);
    } catch (error) {
      LogDev.warning('Streak check-in/popup failed: $error');
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
