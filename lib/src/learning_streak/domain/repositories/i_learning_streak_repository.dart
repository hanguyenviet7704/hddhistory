part of '../../learning_streak.dart';

abstract class ILearningStreakRepository {
  TaskEither<AppException, LearningStreakFetchEntity> getUserLearningStreak(String userId);

  /// Tells the server the user has been in the app long enough for today to
  /// count, and returns the streak that came back.
  TaskEither<AppException, UserLearningStreakEntity> checkInStreak(String userId);

  TaskEither<AppException, StreakPopupConfigEntity> getStreakPopupConfig();
}
