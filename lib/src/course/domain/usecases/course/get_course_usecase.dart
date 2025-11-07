part of '../../../course.dart';

@lazySingleton
class GetCourseUseCase implements UseCaseWithParams<String, CourseEntity> {
  final ICourseRepository _repository;

  GetCourseUseCase(this._repository);

  @override
  TaskEither<AppException, CourseEntity> call(String params) {
    return _repository.getCourse(params);
  }
}
