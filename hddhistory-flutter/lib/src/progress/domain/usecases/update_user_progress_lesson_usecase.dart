part of '../../progress.dart';

class UpdateUserProgressLessonParams {
  final String lessonId;
  final Map<String, dynamic> body;

  UpdateUserProgressLessonParams({required this.lessonId, required this.body});
}

@lazySingleton
class UpdateUserProgressLessonUseCase implements BaseUseCase<UpdateUserProgressLessonParams, UserProgressEntity> {
  final IProgressRepository _repository;

  UpdateUserProgressLessonUseCase(this._repository);

  @override
  TaskEither<AppException, UserProgressEntity> call(UpdateUserProgressLessonParams params) {
    return _repository.updateUserProgressLesson(params.lessonId, params.body);
  }
}
