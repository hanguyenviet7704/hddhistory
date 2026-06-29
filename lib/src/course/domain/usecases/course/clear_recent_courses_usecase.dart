part of '../../../course.dart';

@lazySingleton
class ClearRecentCoursesUseCase implements BaseUseCase<Unit, Unit> {
  final ICourseRepository _repository;

  ClearRecentCoursesUseCase(this._repository);

  @override
  TaskEither<AppException, Unit> call(Unit params) {
    return _repository.clearRecentCourses();
  }
}
