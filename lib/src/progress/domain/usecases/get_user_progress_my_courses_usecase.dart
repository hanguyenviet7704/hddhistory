part of '../../progress.dart';

@lazySingleton
class GetUserProgressMyCoursesUseCase implements UseCaseWithParams<PageBreakRequest, BasePageBreak<CourseEntity>> {
  final IProgressRepository _repository;

  GetUserProgressMyCoursesUseCase(this._repository);

  @override
  TaskEither<AppException, BasePageBreak<CourseEntity>> call(PageBreakRequest params) {
    return _repository.getUserProgressMyCourses(params);
  }
}

