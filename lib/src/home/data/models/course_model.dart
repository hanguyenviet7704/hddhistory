part of '../../home.dart';

@freezed
abstract class CourseModel with _$CourseModel {
  const factory CourseModel({
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @Default(BaseMultiLanguage()) BaseMultiLanguage description,
    @Default('') String image,
    @Default('') String skillsetId,
    @Default(CourseLevel.level1) CourseLevel level,
    @Default(CourseStatus.published) CourseStatus status,
  }) = _CourseModel;

  factory CourseModel.fromJson(Map<String, dynamic> json) => _$CourseModelFromJson(json);
}

enum CourseStatus {
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
    title: title,
    description: description,
    image: image,
    skillsetId: skillsetId,
    level: level,
    status: status,
  );
}
