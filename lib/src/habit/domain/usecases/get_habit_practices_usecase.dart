part of '../../habit.dart';

@lazySingleton
class GetHabitPracticesUseCase {
  final IHabitRepository _repository;

  GetHabitPracticesUseCase(this._repository);

  TaskEither<AppException, List<HabitPracticeEntity>> call(String habitId) =>
      _repository.getHabitPractices(habitId);
}
