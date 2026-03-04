part of '../../learning_streak.dart';

@lazySingleton
class GetUserLearningStreakUseCase implements BaseUseCase<String, UserLearningStreakEntity> {
  final ILearningStreakRepository _repository;

  GetUserLearningStreakUseCase(this._repository);

  @override
  TaskEither<AppException, UserLearningStreakEntity> call(String params) {
    return _repository.getUserLearningStreak(params);
  }
}

