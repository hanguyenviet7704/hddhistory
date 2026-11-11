part of '../../progress.dart';

/// Reads the last cached achievements without hitting the network. Returns an
/// empty list on a cache miss (never fails), so the caller can render
/// cache-first and then refresh in the background.
@lazySingleton
class GetCachedAchievenmentResponsesUseCase {
  final IAchievenmentProgressRepository _repository;

  GetCachedAchievenmentResponsesUseCase(this._repository);

  Future<List<AchievenmentResponseEntity>> call() {
    return _repository.getCachedAchievenmentResponses();
  }
}
