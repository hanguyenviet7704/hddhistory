part of '../../video_lesson.dart';

@lazySingleton
class CreateUserVideoLessonNoteUseCase implements BaseUseCase<UserVideoLessonNoteEntity, UserVideoLessonNoteEntity> {
  final IVideoLessonRepository _repository;

  CreateUserVideoLessonNoteUseCase(this._repository);

  @override
  TaskEither<AppException, UserVideoLessonNoteEntity> call(UserVideoLessonNoteEntity params) {
    return _repository.createUserVideoLessonNote(params);
  }
}
