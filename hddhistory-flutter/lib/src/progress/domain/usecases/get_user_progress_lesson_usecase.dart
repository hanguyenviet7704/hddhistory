part of '../../progress.dart';

@lazySingleton
class GetUserProgressLessonUseCase implements BaseUseCase<UserProgressFilter, LessonResultEntity> {
  final IProgressRepository _repository;

  GetUserProgressLessonUseCase(this._repository);

  @override
  TaskEither<AppException, LessonResultEntity> call(UserProgressFilter params) {
    return _repository.getUserProgressLesson(params);
  }
}
