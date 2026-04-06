part of '../../video_lesson.dart';

@lazySingleton
class DeleteUserVideoLessonNoteUseCase implements BaseUseCase<String, Unit> {
  final IVideoLessonRepository _repository;

  DeleteUserVideoLessonNoteUseCase(this._repository);

  @override
  TaskEither<AppException, Unit> call(String params) {
    return _repository.deleteUserVideoLessonNote(params);
  }
}

