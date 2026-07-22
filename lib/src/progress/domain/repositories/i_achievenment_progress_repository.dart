part of '../../progress.dart';

abstract class IAchievenmentProgressRepository {
  TaskEither<AppException, List<AchievenmentResponseEntity>> getAllAchievenmentResponses();
  TaskEither<AppException, List<CourseLevelProgressEntity>> getCourseLevelProgress(String courseId);

  /// Best-effort read of the last cached achievements (empty list on miss).
  /// Used for cache-first rendering before the network refresh resolves.
  Future<List<AchievenmentResponseEntity>> getCachedAchievenmentResponses();
}
