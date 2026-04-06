part of '../../video_lesson.dart';

@freezed
abstract class LessonVideoModel with _$LessonVideoModel {
  const factory LessonVideoModel({
    @Default('') String url,
    @Default('') String thumbnail,
  }) = _LessonVideoModel;

  factory LessonVideoModel.fromJson(Map<String, dynamic> json) => _$LessonVideoModelFromJson(json);
}

extension LessonVideoModelExtension on LessonVideoModel {
  LessonVideoEntity toEntity() => LessonVideoEntity(
        url: url,
        thumbnail: thumbnail,
      );
}
