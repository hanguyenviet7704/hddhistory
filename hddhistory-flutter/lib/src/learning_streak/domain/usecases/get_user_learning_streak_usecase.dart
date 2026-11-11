part of '../../learning_streak.dart';

@lazySingleton
class GetUserLearningStreakUseCase {
  final ILearningStreakRepository _repository;

  GetUserLearningStreakUseCase(this._repository);

  TaskEither<AppException, LearningStreakFetchEntity> call(String userId) {
    return _repository.getUserLearningStreak(userId);
  }
}
