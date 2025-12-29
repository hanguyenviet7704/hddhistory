part of '../../progress.dart';

abstract class IAchievenmentProgressRepository {
  TaskEither<AppException, List<AchievenmentResponseEntity>> getAllAchievenmentResponses(UserProgressFilter filter);
  TaskEither<AppException, List<CourseLevelProgressEntity>> getCourseLevelProgress(String courseId);
}
