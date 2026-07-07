part of '../../habit.dart';

@lazySingleton
class UpdateUserHabitUseCase {
  final IHabitRepository _repository;

  UpdateUserHabitUseCase(this._repository);

  TaskEither<AppException, UserHabitEntity> call(
    String id, {
    UserHabitStateEntity? state,
    String? reminderTime,
    int? packLength,
  }) => _repository.updateUserHabit(id, state: state, reminderTime: reminderTime, packLength: packLength);
}
