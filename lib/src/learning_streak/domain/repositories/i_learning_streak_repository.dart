part of '../../learning_streak.dart';

abstract class ILearningStreakRepository {
  TaskEither<AppException, LearningStreakFetchEntity> getUserLearningStreak(String userId);

  TaskEither<AppException, StreakPopupConfigEntity> getStreakPopupConfig();
}
