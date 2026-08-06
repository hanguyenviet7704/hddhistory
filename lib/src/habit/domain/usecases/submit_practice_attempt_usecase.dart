part of '../../habit.dart';

@lazySingleton
class SubmitPracticeAttemptUseCase {
  final IHabitRepository _repository;

  SubmitPracticeAttemptUseCase(this._repository);

  /// Also files the day's check-in server-side — never pair this with
  /// [CheckInUserHabitUseCase] for the same practice.
  TaskEither<AppException, UserHabitEntity> call({
    required String userHabitId,
    required HabitCheckinMethodEntity method,
    String? learningItemId,
    List<Map<String, dynamic>>? exercisesResult,
    int? score,
    int? total,
    int? mood,
    String? note,
  }) => _repository.submitPracticeAttempt(
    userHabitId: userHabitId,
    method: method,
    learningItemId: learningItemId,
    exercisesResult: exercisesResult,
    score: score,
    total: total,
    mood: mood,
    note: note,
  );
}
