part of '../../habit.dart';

// Habit reminders were removed on purpose — the lesson return nudge
// (live_activity_return_nudge.dart) is the only local notification the app
// schedules now. What remains here is cleanup: earlier builds registered one
// repeating daily notification per adopted habit via awesome_notifications,
// and those schedules survive an app update on the device — they must be
// cancelled explicitly or they keep firing at 08:00 forever.

const int _habitNotificationIdSeed = 0x811C9DC5;
const int _habitNotificationIdPrime = 0x01000193;
const int _habitNotificationIdMax = 0x7FFFFFFF;

/// Deterministic notification id derived from the user_habit id — the same
/// derivation the old scheduling used, so cancelling by it reaches whatever
/// schedule an older build left behind for that habit.
int habitReminderNotificationId(String userHabitId) {
  var hash = _habitNotificationIdSeed;
  for (final codeUnit in userHabitId.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * _habitNotificationIdPrime) & 0xFFFFFFFF;
  }
  final normalized = hash & _habitNotificationIdMax;
  return normalized == 0 ? 1 : normalized;
}

Future<void> cancelHabitReminder(String userHabitId) async {
  try {
    await NotificationService.cancel(habitReminderNotificationId(userHabitId));
  } catch (error) {
    LogDev.warning('[HabitCubit] cancelHabitReminder failed: $error');
  }
}

/// Cancels the reminder schedule an older build may have left for each habit.
/// Idempotent and best-effort — runs on every habit-screen load; habits whose
/// reminders were already cancelled (or never scheduled) are no-ops.
Future<void> cancelStaleHabitReminders(List<UserHabitEntity> userHabits) async {
  for (final userHabit in userHabits) {
    await cancelHabitReminder(userHabit.id);
  }
}
