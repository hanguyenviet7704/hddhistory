part of '../../video_lesson.dart';

@freezed
abstract class UserVideoLessonNoteModel with _$UserVideoLessonNoteModel {
  const factory UserVideoLessonNoteModel({
    @Default('') String id,
    @Default('') String userId,
    @Default('') String courseId,
    @Default('') String nodeId,
    @Default('') String lessonId,
    @Default('') String content,
    int? atSecond,
  }) = _UserVideoLessonNoteModel;

  factory UserVideoLessonNoteModel.fromJson(Map<String, dynamic> json) => _$UserVideoLessonNoteModelFromJson(json);
}

extension UserVideoLessonNoteModelExtension on UserVideoLessonNoteModel {
  UserVideoLessonNoteEntity toEntity() => UserVideoLessonNoteEntity(
    id: id,
    userId: userId,
    courseId: courseId,
    nodeId: nodeId,
    lessonId: lessonId,
    content: content,
    atSecond: atSecond,
  );
}
