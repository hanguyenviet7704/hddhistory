part of '../../course.dart';

@freezed
abstract class CourseModel with _$CourseModel {
  const factory CourseModel({
    @JsonKey(name: '_id') @Default('') String id,
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @Default(BaseMultiLanguage()) BaseMultiLanguage description,
    @Default('') String image,
    @Default('') String skillsetId,
    @Default(0) int numberOfLesson,
    @Default(CourseLevel.level1) CourseLevel level,
    @Default(CoursePublishStatus.published) CoursePublishStatus status,
  }) = _CourseModel;

  factory CourseModel.fromJson(Map<String, dynamic> json) => _$CourseModelFromJson(json);
}

enum CoursePublishStatus {
  @JsonValue('published')
  published,
  @JsonValue('draft')
  draft,
  @JsonValue('inactive')
  inactive,
}

enum CourseLevel {
  @JsonValue('level 1')
  level1,
  @JsonValue('level 2')
  level2,
}

extension CourseModelExtension on CourseModel {
  CourseEntity toEntity() => CourseEntity(
    id: id,
    title: title,
    description: description,
    image: image,
    skillsetId: skillsetId,
    numberOfLesson: numberOfLesson,
    level: level,
    status: status,
  );
}
