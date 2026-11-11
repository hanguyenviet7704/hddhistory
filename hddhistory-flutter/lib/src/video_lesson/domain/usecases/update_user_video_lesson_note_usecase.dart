part of '../../video_lesson.dart';

@lazySingleton
class UpdateUserVideoLessonNoteUseCase implements BaseUseCase<UserVideoLessonNoteEntity, UserVideoLessonNoteEntity> {
  final IVideoLessonRepository _repository;

  UpdateUserVideoLessonNoteUseCase(this._repository);

  @override
  TaskEither<AppException, UserVideoLessonNoteEntity> call(UserVideoLessonNoteEntity params) {
    return _repository.updateUserVideoLessonNote(params);
  }
}
