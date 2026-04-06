part of '../../video_lesson.dart';

@freezed
abstract class LessonVideoModel with _$LessonVideoModel {
  const factory LessonVideoModel({
    @Default('') String url,
    @Default('') String thumbnail,
    @Default(BaseMultiLanguage()) BaseMultiLanguage summary,
  }) = _LessonVideoModel;

  factory LessonVideoModel.fromJson(Map<String, dynamic> json) => _$LessonVideoModelFromJson(json);
}

extension LessonVideoModelExtension on LessonVideoModel {
  LessonVideoEntity toEntity() => LessonVideoEntity(
        url: url,
        thumbnail: thumbnail,
        summary: summary,
      );
}
