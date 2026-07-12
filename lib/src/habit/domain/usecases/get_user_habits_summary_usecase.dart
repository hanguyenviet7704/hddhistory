part of '../../habit.dart';

@lazySingleton
class GetUserHabitsSummaryUseCase {
  final IHabitRepository _repository;

  GetUserHabitsSummaryUseCase(this._repository);

  TaskEither<AppException, UserHabitSummaryEntity> call() => _repository.getUserHabitsSummary();
}
