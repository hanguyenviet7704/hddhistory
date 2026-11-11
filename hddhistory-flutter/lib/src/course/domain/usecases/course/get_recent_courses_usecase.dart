part of '../../../course.dart';

@lazySingleton
class GetRecentCoursesUseCase implements BaseUseCase<Unit, List<CourseEntity>> {
  final ICourseRepository _repository;

  GetRecentCoursesUseCase(this._repository);

  @override
  TaskEither<AppException, List<CourseEntity>> call(Unit params) {
    return _repository.getRecentCourses();
  }
}
