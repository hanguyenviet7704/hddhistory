part of '../../progress.dart';

@lazySingleton
class GetUserProgressMyCoursesUseCase implements UseCaseWithParams<PageBreakRequest, BasePageBreak<UserProgressEntity>> {
  final IProgressRepository _repository;

  GetUserProgressMyCoursesUseCase(this._repository);

  @override
  TaskEither<AppException, BasePageBreak<UserProgressEntity>> call(PageBreakRequest params) {
    return _repository.getUserProgressMyCourses(params);
  }
}

