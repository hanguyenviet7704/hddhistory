part of '../../progress.dart';

abstract class IProgressRepository {
  TaskEither<AppException, BasePageBreak<UserProgressEntity>> getAllUserProgresss(
    PageBreakRequest request,
  );
  TaskEither<AppException, UserProgressEntity> getUserProgressLesson(String lessonId);
  TaskEither<AppException, UserProgressEntity> getUserProgressKeypoint(String keypointId);
  TaskEither<AppException, UserProgressEntity> getUserProgressExercise(String exerciseId);
  TaskEither<AppException, BasePageBreak<CourseEntity>> getUserProgressMyCourses(
    PageBreakRequest request,
  );
}
