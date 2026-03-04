part of '../../learning_streak.dart';

abstract class ILearningStreakRepository {
  TaskEither<AppException, UserLearningStreakEntity> getUserLearningStreak(String id);
  
}

