part of '../../course.dart';

abstract class ICourseRepository {
  TaskEither<AppException, BasePageBreak<CourseEntity>> getAllCourses(
    PageBreakRequest request,
  );
  TaskEither<AppException, CourseEntity> getCourse(String id);
  TaskEither<AppException, RoadmapEntity> getRoadmap(String id);
}
