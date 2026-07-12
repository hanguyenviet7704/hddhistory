part of '../../habit.dart';

// [CONFIRM-6 in design.md] reminders are local-only in v1 (no server push) —
// scheduled/cancelled client-side via the app's existing
// AwesomeLocalNotificationService, one recurring daily notification per
// adopted habit.

const int _habitNotificationIdSeed = 0x811C9DC5;
const int _habitNotificationIdPrime = 0x01000193;
const int _habitNotificationIdMax = 0x7FFFFFFF;

/// Deterministic notification id derived from the user_habit id, so the same
/// habit always resolves to the same schedule slot across adopt/cancel calls
/// (no id bookkeeping needed on the client).
int habitReminderNotificationId(String userHabitId) {
  var hash = _habitNotificationIdSeed;
  for (final codeUnit in userHabitId.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * _habitNotificationIdPrime) & 0xFFFFFFFF;
  }
  final normalized = hash & _habitNotificationIdMax;
  return normalized == 0 ? 1 : normalized;
}

/// Next occurrence of [reminderTime] ("HH:mm"); today if that time hasn't
/// passed yet, otherwise the schedule still recurs correctly from tomorrow
/// once `repeats: true` takes over (awesome_notifications matches on the
/// time-of-day, not the initial date).
DateTime _nextReminderOccurrence(String reminderTime) {
  final parts = reminderTime.split(':');
  final hour = int.tryParse(parts.elementAtOrNull(0) ?? '') ?? 8;
  final minute = int.tryParse(parts.elementAtOrNull(1) ?? '') ?? 0;
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day, hour, minute);
}

Future<void> scheduleHabitReminder(UserHabitEntity userHabit) async {
  final reminderTime = userHabit.reminderTime;
  if (reminderTime == null || reminderTime.isEmpty) return;

  try {
    await NotificationService.scheduleLocal(
      NotificationScheduleRequest(
        notification: NotificationRequest(
          id: habitReminderNotificationId(userHabit.id),
          title: userHabit.displayTitle,
          body: userHabit.displayTitle,
        ),
        scheduledAt: _nextReminderOccurrence(reminderTime),
        repeats: true,
      ),
    );
  } catch (error) {
    // Local reminders are best-effort — a scheduling failure (e.g. permission
    // denied) must never block the adopt/resume flow itself.
    LogDev.warning('[HabitCubit] scheduleHabitReminder failed: $error');
  }
}

Future<void> cancelHabitReminder(String userHabitId) async {
  try {
    await NotificationService.cancel(habitReminderNotificationId(userHabitId));
  } catch (error) {
    LogDev.warning('[HabitCubit] cancelHabitReminder failed: $error');
  }
}
