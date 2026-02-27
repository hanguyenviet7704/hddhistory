part of '../../../course.dart';

@lazySingleton
class GetCourseUseCase implements BaseUseCase<String, CourseEntity> {
  final ICourseRepository _repository;

  GetCourseUseCase(this._repository);

  @override
  TaskEither<AppException, CourseEntity> call(String courseId) {
    return _repository.getCourse(courseId);
  }
}
