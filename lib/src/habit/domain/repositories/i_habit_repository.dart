part of '../../habit.dart';

abstract class IHabitRepository {
  TaskEither<AppException, List<HabitEntity>> getHabits({String? skillsetId, String? keypointId});

  TaskEither<AppException, List<UserHabitEntity>> getUserHabits({UserHabitStateEntity? state});

  TaskEither<AppException, UserHabitSummaryEntity> getUserHabitsSummary();

  /// Admin-configured free-tier cap on simultaneously-active habits.
  TaskEither<AppException, int> getFreeActiveSlots();

  /// Combined Habit-tab bootstrap: habits + summary + free-tier cap in one
  /// round trip — replaces separate calls to [getUserHabits],
  /// [getUserHabitsSummary] and [getFreeActiveSlots] on the tab's initial load.
  TaskEither<AppException, HabitScreenEntity> getHabitScreen({UserHabitStateEntity? state});

  /// Best-effort read of the last cached combined habit screen (null on a
  /// cache miss). Used for cache-first rendering before the network refresh
  /// resolves.
  Future<HabitScreenEntity?> getCachedHabitScreen();

  TaskEither<AppException, UserHabitEntity> adoptHabit({
    required String habitId,
    String? reminderTime,
    int? packLength,
    String? sourceKeypointId,
    String? sourceCourseId,
    String? reanchorReasonId,
    BaseMultiLanguage? reanchorReason,
  });

  TaskEither<AppException, UserHabitEntity> updateUserHabit(
    String id, {
    UserHabitStateEntity? state,
    String? reminderTime,
    int? packLength,
  });

  TaskEither<AppException, Unit> removeUserHabit(String id);

  TaskEither<AppException, UserHabitEntity> checkIn(
    String id, {
    required bool done,
    DateTime? date,
    String? note,
  });

  TaskEither<AppException, List<HabitCheckinEntity>> getCheckins(String id);

  TaskEither<AppException, List<ReanchorReasonEntity>> getReanchorReasons(String courseId);
}
