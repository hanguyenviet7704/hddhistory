part of '../../learning_streak.dart';

@lazySingleton
class GetUserLearningStreakUseCase {
  final ILearningStreakRepository _repository;

  GetUserLearningStreakUseCase(this._repository);

  TaskEither<AppException, UserLearningStreakEntity> call() {
    return _repository.getUserLearningStreak();
  }
}

