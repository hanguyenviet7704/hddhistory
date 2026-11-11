part of '../../achievenment.dart';

@freezed
abstract class AchievenmentResponseEntity with _$AchievenmentResponseEntity {
  const factory AchievenmentResponseEntity({
    @Default('') String categoryId,
    @Default(BaseMultiLanguage()) BaseMultiLanguage categoryTitle,
    @Default([]) List<CourseLevelProgressEntity> courses,
    // Category-wide keypoint totals (all levels of all courses) — drives the
    // fractional learning-progress bar so partial progress shows a real %
    // instead of 0 until a whole course is 100% finished.
    @Default(0) int totalKeypoints,
    @Default(0) int completedKeypoints,
  }) = _AchievenmentResponseEntity;

  factory AchievenmentResponseEntity.fromJson(Map<String, dynamic> json) => _$AchievenmentResponseEntityFromJson(json);
}

extension AchievenmentResponseEntityExtension on AchievenmentResponseEntity {
  int get totalCourse => courses.length;
  int get completedCourse => courses.where((course) => course.isCompleted).length;
}