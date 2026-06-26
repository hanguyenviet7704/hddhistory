part of '../../course.dart';

abstract class ICourseRepository {
  TaskEither<AppException, BasePageBreak<CourseEntity>> getAllCourses(
    PageBreakRequest<CourseFilterRequest> request,
  );
  TaskEither<AppException, CourseEntity> getCourse(String id);
  TaskEither<AppException, RoadmapEntity> getRoadmap(String id);

  TaskEither<AppException, List<String>> getSearchHistory();
  TaskEither<AppException, Unit> saveSearchQuery(String query);
  TaskEither<AppException, Unit> clearSearchHistory();
}
