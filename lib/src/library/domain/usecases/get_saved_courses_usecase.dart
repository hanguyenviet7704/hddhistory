part of '../../library.dart';

@lazySingleton
class GetSavedCoursesUseCase {
  final ISavedRepository _repository;

  GetSavedCoursesUseCase(this._repository);

  TaskEither<AppException, BasePageBreak<CourseEntity>> call({
    required int page,
    required int take,
    required SavedCourseFilter filter,
  }) => _repository.getSavedCourses(page: page, take: take, filter: filter);
}
