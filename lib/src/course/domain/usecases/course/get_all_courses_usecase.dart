part of '../../../course.dart';

@lazySingleton
class GetAllCoursesUseCase implements UseCaseWithParams<PageBreakRequest, BasePageBreak<CourseEntity>> {
  final ICourseRepository _repository;

  GetAllCoursesUseCase(this._repository);

  @override
  TaskEither<AppException, BasePageBreak<CourseEntity>> call(PageBreakRequest params) {
    return _repository.getAllCourses(params);
  }
}
