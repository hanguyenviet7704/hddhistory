part of '../../video_lesson.dart';

@freezed
abstract class LessonVideoEntity with _$LessonVideoEntity {
  const factory LessonVideoEntity({
    @Default('') String url,
    @Default('') String thumbnail,
  }) = _LessonVideoEntity;

  factory LessonVideoEntity.fromJson(Map<String, dynamic> json) => _$LessonVideoEntityFromJson(json);
}
