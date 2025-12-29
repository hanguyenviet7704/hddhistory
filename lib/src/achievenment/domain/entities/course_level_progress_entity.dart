part of '../../achievenment.dart';

@freezed
abstract class CourseLevelProgressEntity with _$CourseLevelProgressEntity {
  const factory CourseLevelProgressEntity({
    @Default(CourseLevel.level1) CourseLevel level,
    @Default('') String lightBadge,
    @Default('') String darkBadge,
    @Default(BaseMultiLanguage()) BaseMultiLanguage titleBadge,
    @Default('') String courseId,
    @Default(BaseMultiLanguage()) BaseMultiLanguage courseTitle,
    @Default(0) int totalKeypoints,
    @Default(0) int completedKeypoints,
    @Default(false) bool isCompleted,
  }) = _CourseLevelProgressEntity;

  factory CourseLevelProgressEntity.fromJson(Map<String, dynamic> json) => _$CourseLevelProgressEntityFromJson(json);
}
