part of '../../habit.dart';

/// Combined Habit-tab bootstrap: habits + summary + free-tier cap in one
/// round trip — replaces separate calls to [GetUserHabitsUseCase],
/// [GetUserHabitsSummaryUseCase] and [GetHabitConfigUseCase] on the tab's
/// initial load.
@lazySingleton
class GetHabitScreenUseCase {
  final IHabitRepository _repository;

  GetHabitScreenUseCase(this._repository);

  TaskEither<AppException, HabitScreenEntity> call({UserHabitStateEntity? state}) => _repository.getHabitScreen(state: state);
}
