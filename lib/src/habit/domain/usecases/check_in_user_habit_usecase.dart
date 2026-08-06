part of '../../habit.dart';

@lazySingleton
class CheckInUserHabitUseCase {
  final IHabitRepository _repository;

  CheckInUserHabitUseCase(this._repository);

  TaskEither<AppException, UserHabitEntity> call(
    String id, {
    required bool done,
    DateTime? date,
    String? note,
    HabitCheckinMethodEntity? method,
    int? mood,
    int? score,
  }) => _repository.checkIn(
    id,
    done: done,
    date: date,
    note: note,
    method: method,
    mood: mood,
    score: score,
  );
}
