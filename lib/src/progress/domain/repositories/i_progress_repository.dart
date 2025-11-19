part of '../../progress.dart';

abstract class IProgressRepository {
  TaskEither<AppException, UserProgressEntity> getAllUserProgresss(UserProgressFilter filter);
  TaskEither<AppException, LessonResultEntity> getUserProgressLesson(UserProgressFilter filter);
  TaskEither<AppException, KeypointResultEntity> getUserProgressKeypoint(UserProgressFilter filter);
  TaskEither<AppException, ExerciseResultEntity> getUserProgressExercise(UserProgressFilter filter);
  TaskEither<AppException, UserProgressEntity> updateUserProgressLesson(String lessonId, Map<String, dynamic> body);
  TaskEither<AppException, UserProgressEntity> updateUserProgressKeypoint(Map<String, dynamic> body);
  TaskEither<AppException, UserProgressEntity> updateUserProgressExercise(Map<String, dynamic> body);
  TaskEither<AppException, BasePageBreak<CourseEntity>> getUserProgressMyCourses(PageBreakRequest request);
}
