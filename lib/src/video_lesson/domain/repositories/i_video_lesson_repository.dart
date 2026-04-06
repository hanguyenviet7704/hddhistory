part of '../../video_lesson.dart';

abstract class IVideoLessonRepository {
  TaskEither<AppException, BasePageBreak<UserVideoLessonNoteEntity>> getAllUserVideoLessonNotes(
    PageBreakRequest request,
  );
  TaskEither<AppException, UserVideoLessonNoteEntity> getUserVideoLessonNote(String id);
  TaskEither<AppException, LearningItemEntity> getLearningItem(String id);
  TaskEither<AppException, UserVideoLessonNoteEntity> createUserVideoLessonNote(UserVideoLessonNoteEntity entity);
  TaskEither<AppException, UserVideoLessonNoteEntity> updateUserVideoLessonNote(UserVideoLessonNoteEntity entity);
  TaskEither<AppException, Unit> deleteUserVideoLessonNote(String id);
}

