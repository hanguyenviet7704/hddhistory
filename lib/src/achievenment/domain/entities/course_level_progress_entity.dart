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

extension CourseLevelProgressEntityExtension on CourseLevelProgressEntity {
  String get badgeUrl {
    if (isCompleted) return lightBadge.trim();
    if (darkBadge.trim().isNotEmpty) return darkBadge.trim();
    return lightBadge.trim();
  }

  double get progress {
    if (totalKeypoints <= 0) return 0;
    return completedKeypoints / totalKeypoints;
  }

  int get progressPercent {
    return (progress * 100).clamp(0, 100).round();
  }
}