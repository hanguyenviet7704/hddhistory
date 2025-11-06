part of '../../progress.dart';

abstract class IProgressRepository {
  TaskEither<AppException, BasePageBreak<UserProgressEntity>> getAllUserProgresss(
    PageBreakRequest request,
  );
  TaskEither<AppException, UserProgressEntity> updateUserProgressLesson(String lessonId);
  TaskEither<AppException, UserProgressEntity> updateUserProgressKeypoint(String keypointId);
  TaskEither<AppException, UserProgressEntity> updateUserProgressExercise(String exerciseId);
  TaskEither<AppException, BasePageBreak<CourseEntity>> getUserProgressMyCourses(
    PageBreakRequest request,
  );
}
