part of '../../course.dart';

@lazySingleton
class GetLessonUseCase implements UseCaseWithParams<String, LessonEntity> {
  final ICourseLessonRepository _repository;

  GetLessonUseCase(this._repository);

  @override
  TaskEither<AppException, LessonEntity> call(String params) {
    return _repository.getLesson(params);
  }
}

