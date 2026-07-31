part of '../../learning_streak.dart';

/// The calendar day a streak is accounted against, in the USER's timezone.
///
/// This has to agree with how the API buckets a check-in. The app sends its UTC
/// offset on every request (`x-timezone-offset`, see `AppInterceptor`) and the
/// server files the day by that local calendar, so every once-a-day latch on
/// this side must use the same definition. Keying them by UTC day instead — what
/// this code did before — put a 00:30 session in Vietnam on the previous day,
/// and reset the in-app timer at 07:00 local rather than at midnight.
class StreakDay {
  const StreakDay._();

  /// Local midnight of the day [at] falls in. This is the value stored in
  /// [LearningStreakState.lastCheckInDate] and `lastStreakCountedDate`.
  static DateTime resolve(DateTime at) {
    final local = at.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  static DateTime today() => resolve(DateTime.now());

  /// Stable `yyyy-MM-dd` key for local-store bookkeeping.
  static String key(DateTime at) {
    final day = resolve(at);
    final month = day.month.toString().padLeft(2, '0');
    final dayOfMonth = day.day.toString().padLeft(2, '0');
    return '${day.year}-$month-$dayOfMonth';
  }

  static bool isSame(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return resolve(a) == resolve(b);
  }
}
