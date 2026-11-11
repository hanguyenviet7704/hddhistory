part of '../../video_lesson.dart';

@freezed
abstract class VideoLessonNoteFilterEntity with _$VideoLessonNoteFilterEntity implements JsonRequestConvertible {
  const VideoLessonNoteFilterEntity._();

  const factory VideoLessonNoteFilterEntity({
    @Default('') String courseId,
    @Default('') String nodeId,
    @Default('') String lessonId,
  }) = _VideoLessonNoteFilterEntity;

  factory VideoLessonNoteFilterEntity.fromJson(Map<String, dynamic> json) => _$VideoLessonNoteFilterEntityFromJson(json);

  @override
  Map<String, dynamic> toJson() => {
    'courseId': courseId,
    'nodeId': nodeId,
    'lessonId': lessonId,
  };

  String get scopeKey => '${courseId.trim()}::${nodeId.trim()}::${lessonId.trim()}';
}
