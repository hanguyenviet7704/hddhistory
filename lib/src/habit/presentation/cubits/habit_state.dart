part of '../../habit.dart';

// Mirrors the server's FREE_ACTIVE_HABIT_SLOTS (meup-api user-habit.service.ts)
// — display-only; the server remains the source of truth and enforcement.
const int kFreeActiveHabitSlots = 3;

enum HabitTabToggle { task, habit }

enum HabitPageStatus { initial, loading, success, failure }

@freezed
abstract class HabitState with _$HabitState {
  const factory HabitState({
    @Default(HabitPageStatus.initial) HabitPageStatus status,
    @Default([]) List<UserHabitEntity> userHabits,
    @Default(UserHabitSummaryEntity()) UserHabitSummaryEntity summary,
    // Free-tier active-habit cap, admin-configurable server-side; the const
    // is only the pre-fetch default.
    @Default(kFreeActiveHabitSlots) int freeActiveSlots,
    @Default(HabitTabToggle.task) HabitTabToggle toggle,
    String? errorMessage,
    // Day the user tapped/dismissed the Home check-in reminder card (§9.4);
    // the card stays hidden for the rest of that local day.
    DateTime? homeReminderDismissedOn,
    // Day the Sunday Weekly recap was auto-shown (§9.9); prevents re-opening it
    // repeatedly on the same Sunday. Legacy device-clock fallback — used only
    // when the server hasn't provided its week start (older API).
    DateTime? weeklyRecapShownOn,
    // Server week-start (weekStartDate) the recap was last shown for. Preferred
    // dedup key: shows the recap at most once per server-week, independent of
    // the device clock.
    DateTime? weeklyRecapShownWeekStart,
    // Courses whose Re-anchor prompt (§9.1) has already been shown this session,
    // so it appears at most once per course.
    @Default(<String>{}) Set<String> reanchorShownCourseIds,
    // The re-anchor reason the user picked per course (keyed by courseId),
    // remembered from the Re-anchor screen so it can be attached when a habit
    // is later adopted from that course's keypoint — it becomes the tracker
    // cluster title (§9.5).
    @Default(<String, ReanchorReasonEntity>{}) Map<String, ReanchorReasonEntity> reanchorReasonByCourse,
  }) = _HabitState;

  factory HabitState.initial() => const HabitState();
}

/// True when the tab should (re)fetch: no data loaded yet, an earlier load
/// failed, or nothing is currently loading. Mirrors [shouldSelfHealHomeData] —
/// a genuinely empty habit list (new user) also refetches on each entry,
/// same accepted trade-off, since there's no cheap way to distinguish
/// "confirmed empty" from "never loaded" without an extra flag.
bool shouldEnsureHabitsReload(HabitState state) => state.status != HabitPageStatus.loading && state.userHabits.isEmpty;

extension HabitStateX on HabitState {
  List<UserHabitEntity> get activeHabits => userHabits.where((habit) => habit.isActive).toList();
  int get activeCount => activeHabits.length;
  int get doneTodayCount => activeHabits.where((habit) => habit.todayDone).length;
  bool get allDoneToday => activeHabits.isNotEmpty && doneTodayCount == activeCount;
  bool get isEmpty => status == HabitPageStatus.success && userHabits.isEmpty;

  /// Active habits not yet checked in today — the "N" in the Home reminder
  /// card and "tasks to complete" (§9.4/§9.5).
  int get uncheckedTodayCount => activeHabits.where((habit) => !habit.todayDone).length;

  /// Home reminder card visibility (§9.4 FR4.3): at least one habit still to
  /// check today, and the card hasn't been tapped/dismissed yet this local day.
  bool get showHomeReminder {
    if (uncheckedTodayCount <= 0) return false;
    final dismissedOn = homeReminderDismissedOn;
    return dismissedOn == null || !DateUtils.isSameDay(dismissedOn, DateTime.now());
  }

  /// Weekly recap auto-open (§9.9 FR9.1): the recap day, with at least one
  /// active habit, and not already shown for this week.
  ///
  /// The "is it recap day?" decision is driven by the SERVER ([summary.isRecapDay]
  /// + [summary.weekStartDate]) so it doesn't trust the device clock. When the
  /// server hasn't supplied a week start (older API not yet deployed), it falls
  /// back to the previous local-Sunday behaviour so nothing regresses. Requires
  /// [HabitCubit.loadSummary] to have run first (see home_page `_maybeOpenWeeklyRecap`).
  bool get shouldShowWeeklyRecap {
    if (activeHabits.isEmpty) return false;

    // QA override (debug + non-prod only): open the recap on any day so it can
    // be verified without waiting for the server's recap day. See HabitQaFlags.
    if (HabitQaFlags.forceWeeklyRecap) return true;

    final serverWeekStart = summary.weekStartDate;
    if (serverWeekStart != null) {
      if (!summary.isRecapDay) return false;
      final shownWeek = weeklyRecapShownWeekStart;
      return shownWeek == null || !DateUtils.isSameDay(shownWeek, serverWeekStart);
    }

    // Fallback: legacy device-clock behaviour (server week start unavailable).
    final now = DateTime.now();
    if (now.weekday != DateTime.sunday) return false;
    final shownOn = weeklyRecapShownOn;
    return shownOn == null || !DateUtils.isSameDay(shownOn, now);
  }
}
