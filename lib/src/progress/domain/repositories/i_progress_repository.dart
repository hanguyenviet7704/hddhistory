part of '../../progress.dart';

abstract class IProgressRepository {
  TaskEither<AppException, BasePageBreak<UserProgressEntity>> getAllUserProgresss(PageBreakRequest request);
  TaskEither<AppException, UserProgressEntity> updateUserProgressLesson(String lessonId, Map<String, dynamic> body);
  TaskEither<AppException, UserProgressEntity> updateUserProgressKeypoint(String keypointId, Map<String, dynamic> body);
  TaskEither<AppException, UserProgressEntity> updateUserProgressExercise(String exerciseId, Map<String, dynamic> body);
  TaskEither<AppException, BasePageBreak<CourseEntity>> getUserProgressMyCourses(PageBreakRequest request);
}
