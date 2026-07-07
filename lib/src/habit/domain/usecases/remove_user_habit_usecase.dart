part of '../../habit.dart';

@lazySingleton
class RemoveUserHabitUseCase implements BaseUseCase<String, Unit> {
  final IHabitRepository _repository;

  RemoveUserHabitUseCase(this._repository);

  @override
  TaskEither<AppException, Unit> call(String id) => _repository.removeUserHabit(id);
}
