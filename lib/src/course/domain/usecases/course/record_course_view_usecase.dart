part of '../../../course.dart';

@lazySingleton
class RecordCourseViewUseCase implements BaseUseCase<String, Unit> {
  final ICourseRepository _repository;

  RecordCourseViewUseCase(this._repository);

  @override
  TaskEither<AppException, Unit> call(String courseId) {
    return _repository.recordCourseView(courseId);
  }
}
