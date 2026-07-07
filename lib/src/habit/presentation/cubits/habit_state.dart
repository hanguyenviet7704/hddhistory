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
    @Default(HabitTabToggle.task) HabitTabToggle toggle,
    String? errorMessage,
    // Day the user tapped/dismissed the Home check-in reminder card (§9.4);
    // the card stays hidden for the rest of that local day.
    DateTime? homeReminderDismissedOn,
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
}
