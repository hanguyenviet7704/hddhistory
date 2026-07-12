part of '../../habit.dart';

@lazySingleton
class GetHabitsUseCase {
  final IHabitRepository _repository;

  GetHabitsUseCase(this._repository);

  TaskEither<AppException, List<HabitEntity>> call({String? skillsetId, String? keypointId}) => _repository.getHabits(skillsetId: skillsetId, keypointId: keypointId);
}
