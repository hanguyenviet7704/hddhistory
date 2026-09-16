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

  TaskEither<AppException, List<CourseEntity>> getRecentCourses();
  TaskEither<AppException, Unit> recordCourseView(String courseId);

  /// The whole Explore tab, sections already in render order. [seed] keeps the
  /// shuffled strips stable for one session.
  TaskEither<AppException, List<ExploreSectionEntity>> getExploreSections(int seed);
  TaskEither<AppException, Unit> clearRecentCourses();
}
