part of '../../../course.dart';

@lazySingleton
class GetCourseLessonUseCase implements BaseUseCase<String, LessonEntity> {
  final ICourseLessonRepository _repository;

  GetCourseLessonUseCase(this._repository);

  @override
  TaskEither<AppException, LessonEntity> call(String params) {
    return _repository.getCourseLesson(params);
  }
}
