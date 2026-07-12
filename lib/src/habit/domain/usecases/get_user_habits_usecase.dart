part of '../../habit.dart';

@lazySingleton
class GetUserHabitsUseCase {
  final IHabitRepository _repository;

  GetUserHabitsUseCase(this._repository);

  TaskEither<AppException, List<UserHabitEntity>> call({UserHabitStateEntity? state}) => _repository.getUserHabits(state: state);
}
