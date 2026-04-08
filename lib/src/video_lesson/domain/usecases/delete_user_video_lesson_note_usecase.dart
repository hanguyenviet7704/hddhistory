part of '../../video_lesson.dart';

@lazySingleton
class DeleteUserVideoLessonNoteUseCase implements BaseUseCase<UserVideoLessonNoteEntity, Unit> {
  final IVideoLessonRepository _repository;

  DeleteUserVideoLessonNoteUseCase(this._repository);

  @override
  TaskEither<AppException, Unit> call(UserVideoLessonNoteEntity params) {
    return _repository.deleteUserVideoLessonNote(params);
  }
}
