part of '../../achievenment.dart';

@freezed
abstract class CourseLevelProgressModel with _$CourseLevelProgressModel {
  const factory CourseLevelProgressModel({
    @JsonKey(unknownEnumValue: CourseLevel.unknown) @Default(CourseLevel.level1) CourseLevel level,
    @Default('') String lightBadge,
    @Default('') String darkBadge,
    @Default(BaseMultiLanguage()) BaseMultiLanguage titleBadge,
    @Default('') String courseId,
    @Default(BaseMultiLanguage()) BaseMultiLanguage courseTitle,
    @Default(0) int totalKeypoints,
    @Default(0) int completedKeypoints,
    @Default(false) bool isCompleted,
  }) = _CourseLevelProgressModel;

  factory CourseLevelProgressModel.fromJson(Map<String, dynamic> json) => _$CourseLevelProgressModelFromJson(json);
}

extension CourseLevelProgressModelExtension on CourseLevelProgressModel {
  CourseLevelProgressEntity toEntity() => CourseLevelProgressEntity(
    level: level,
    lightBadge: lightBadge,
    darkBadge: darkBadge,
    titleBadge: titleBadge,
    courseId: courseId,
    courseTitle: courseTitle,
    totalKeypoints: totalKeypoints,
    completedKeypoints: completedKeypoints,
    isCompleted: isCompleted,
  );
}
