part of '../../progress.dart';

@lazySingleton
class UpdateUserProgressLessonUseCase implements UseCaseWithParams<String, UserProgressEntity> {
  final IProgressRepository _repository;

  UpdateUserProgressLessonUseCase(this._repository);

  @override
  TaskEither<AppException, UserProgressEntity> call(String params) {
    return _repository.updateUserProgressLesson(params);
  }
}
