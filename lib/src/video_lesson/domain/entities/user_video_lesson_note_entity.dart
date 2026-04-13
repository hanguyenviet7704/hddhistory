part of '../../video_lesson.dart';

@freezed
abstract class UserVideoLessonNoteEntity with _$UserVideoLessonNoteEntity {
  const factory UserVideoLessonNoteEntity({
    @Default('') String id,
    @Default('') String userId,
    @Default('') String courseId,
    @Default('') String nodeId,
    @Default('') String lessonId,
    @Default('') String content,
    int? atSecond,
  }) = _UserVideoLessonNoteEntity;

  factory UserVideoLessonNoteEntity.fromJson(Map<String, dynamic> json) => _$UserVideoLessonNoteEntityFromJson(json);
}
