part of '../../habit.dart';

@lazySingleton
class AdoptHabitUseCase {
  final IHabitRepository _repository;

  AdoptHabitUseCase(this._repository);

  TaskEither<AppException, UserHabitEntity> call({
    required String habitId,
    String? reminderTime,
    int? packLength,
  }) => _repository.adoptHabit(habitId: habitId, reminderTime: reminderTime, packLength: packLength);
}
