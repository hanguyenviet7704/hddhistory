part of '../../lesson.dart';

@freezed
abstract class LessonModel with _$LessonModel {
  const factory LessonModel({
    @Default('') @JsonKey(name: '_id') String id,
    @Default('') String courseId,
    @Default(LessonType.lesson) LessonType type,
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @Default(BaseMultiLanguage()) BaseMultiLanguage description,
    @Default('') String image,
    @Default(LessonPublishStatus.draft) LessonPublishStatus status,
    @Default([]) List<String> keypoints,
    @Default(BaseMultiLanguage()) BaseMultiLanguage estimateCompleTime,
    @Default('') String icon,
    @Default(0) int index,
  }) = _LessonModel;

  factory LessonModel.fromJson(Map<String, dynamic> json) => _$LessonModelFromJson(json);
}

enum LessonPublishStatus {
  @JsonValue('published')
  published,

  @JsonValue('draft')
  draft,

  @JsonValue('inactive')
  inactive,
}

enum LessonType {
  @JsonValue('lesson')
  lesson,

  @JsonValue('entrance')
  entrance,

  @JsonValue('output')
  output,
}

extension LessonModelExtension on LessonModel {
  LessonEntity toEntity() => LessonEntity(
    id: id,
    courseId: courseId,
    type: type,
    title: title,
    description: description,
    image: image,
    status: status,
    keypoints: keypoints,
    estimateCompleTime: estimateCompleTime,
    icon: icon,
    index: index,
  );
}
