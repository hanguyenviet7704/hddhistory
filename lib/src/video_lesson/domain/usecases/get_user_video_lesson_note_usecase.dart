part of '../../video_lesson.dart';

@lazySingleton
class GetUserVideoLessonNoteUseCase implements BaseUseCase<String, UserVideoLessonNoteEntity> {
  final IVideoLessonRepository _repository;

  GetUserVideoLessonNoteUseCase(this._repository);

  @override
  TaskEither<AppException, UserVideoLessonNoteEntity> call(String params) {
    return _repository.getUserVideoLessonNote(params);
  }
}
