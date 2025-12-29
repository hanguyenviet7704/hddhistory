part of '../../progress.dart';

abstract class IAchievenmentProgressRepository {
  TaskEither<AppException, List<AchievenmentResponseEntity>> getAllAchievenmentResponses();
  TaskEither<AppException, List<CourseLevelProgressEntity>> getCourseLevelProgress(String courseId);
}
