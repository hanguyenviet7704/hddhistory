part of '../../progress.dart';

@lazySingleton
class GetUserProgressLessonUseCase implements UseCaseWithParams<String, UserProgressEntity> {
  final IProgressRepository _repository;

  GetUserProgressLessonUseCase(this._repository);

  @override
  TaskEither<AppException, UserProgressEntity> call(String params) {
    return _repository.getUserProgressLesson(params);
  }
}

