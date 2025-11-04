part of '../../course.dart';

abstract class ICourseLessonRepository {
  TaskEither<AppException, BasePageBreak<LessonEntity>> getAllLessons(
    PageBreakRequest request,
  );
  TaskEither<AppException, LessonEntity> getLesson(String id);
}

