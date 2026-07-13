part of '../../habit.dart';

@lazySingleton
class GetHabitConfigUseCase {
  final IHabitRepository _repository;

  GetHabitConfigUseCase(this._repository);

  /// The admin-configured free-tier active-habit cap.
  TaskEither<AppException, int> call() => _repository.getFreeActiveSlots();
}
