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
    @JsonKey(unknownEnumValue: CoursePublishStatus.unknown) @Default(CoursePublishStatus.published) CoursePublishStatus status,
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
  @JsonValue('unknown')
  unknown,
}

extension CourseModelExtension on CourseModel {
  CourseEntity toEntity() => CourseEntity(
    id: id,
    title: title,
    description: description,
    image: image,
    skillsetId: skillsetId,
    numberOfLesson: numberOfLesson,
    status: status,
  );
}
