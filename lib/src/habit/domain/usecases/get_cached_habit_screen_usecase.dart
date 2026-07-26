part of '../../habit.dart';

/// Reads the last cached combined habit screen without hitting the network.
/// Returns null on a cache miss (never fails), so the caller can render
/// cache-first and then refresh in the background.
@lazySingleton
class GetCachedHabitScreenUseCase {
  final IHabitRepository _repository;

  GetCachedHabitScreenUseCase(this._repository);

  Future<HabitScreenEntity?> call() => _repository.getCachedHabitScreen();
}
