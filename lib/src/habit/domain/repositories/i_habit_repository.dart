part of '../../habit.dart';

abstract class IHabitRepository {
  TaskEither<AppException, List<HabitEntity>> getHabits({String? skillsetId, String? keypointId});

  TaskEither<AppException, List<UserHabitEntity>> getUserHabits({UserHabitStateEntity? state});

  TaskEither<AppException, UserHabitSummaryEntity> getUserHabitsSummary();

  TaskEither<AppException, UserHabitEntity> adoptHabit({
    required String habitId,
    String? reminderTime,
    int? packLength,
    String? sourceKeypointId,
    String? sourceCourseId,
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
