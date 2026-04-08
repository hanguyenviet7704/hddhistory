part of '../../video_lesson.dart';

@lazySingleton
class GetAllUserVideoLessonNotesUseCase implements BaseUseCase<PageBreakRequest<VideoLessonNoteFilterEntity>, BasePageBreak<UserVideoLessonNoteEntity>> {
  final IVideoLessonRepository _repository;

  GetAllUserVideoLessonNotesUseCase(this._repository);

  @override
  TaskEither<AppException, BasePageBreak<UserVideoLessonNoteEntity>> call(PageBreakRequest<VideoLessonNoteFilterEntity> params) {
    return _repository.getAllUserVideoLessonNotes(params);
  }
}
