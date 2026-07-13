part of '../../habit.dart';

@lazySingleton
class AdoptHabitUseCase {
  final IHabitRepository _repository;

  AdoptHabitUseCase(this._repository);

  TaskEither<AppException, UserHabitEntity> call({
    required String habitId,
    String? reminderTime,
    int? packLength,
    String? sourceKeypointId,
    String? sourceCourseId,
    String? reanchorReasonId,
    BaseMultiLanguage? reanchorReason,
  }) => _repository.adoptHabit(
    habitId: habitId,
    reminderTime: reminderTime,
    packLength: packLength,
    sourceKeypointId: sourceKeypointId,
    sourceCourseId: sourceCourseId,
    reanchorReasonId: reanchorReasonId,
    reanchorReason: reanchorReason,
  );
}
