part of '../../course.dart';

abstract class ICourseLessonRepository {
  TaskEither<AppException, BasePageBreak<LessonEntity>> getAllCourseLessons(
    PageBreakRequest request,
  );
  TaskEither<AppException, LessonEntity> getCourseLesson(String id);
}
