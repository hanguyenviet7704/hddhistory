part of '../../learning_streak.dart';

@lazySingleton
class CheckInStreakUseCase {
  final ILearningStreakRepository _repository;

  CheckInStreakUseCase(this._repository);

  TaskEither<AppException, UserLearningStreakEntity> call(String userId) {
    return _repository.checkInStreak(userId);
  }
}
