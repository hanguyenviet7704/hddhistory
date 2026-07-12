part of '../../habit.dart';

@lazySingleton
class GetHabitCheckinsUseCase {
  final IHabitRepository _repository;

  GetHabitCheckinsUseCase(this._repository);

  TaskEither<AppException, List<HabitCheckinEntity>> call(String id) => _repository.getCheckins(id);
}
