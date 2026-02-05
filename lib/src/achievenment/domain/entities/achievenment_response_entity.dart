part of '../../achievenment.dart';

@freezed
abstract class AchievenmentResponseEntity with _$AchievenmentResponseEntity {
  const factory AchievenmentResponseEntity({
    @Default('') String skillsetId,
    @Default(BaseMultiLanguage()) BaseMultiLanguage skillsetTitle,
    @Default([]) List<CourseLevelProgressEntity> courses,
  }) = _AchievenmentResponseEntity;

  factory AchievenmentResponseEntity.fromJson(Map<String, dynamic> json) => _$AchievenmentResponseEntityFromJson(json);
}

extension AchievenmentResponseEntityExtension on AchievenmentResponseEntity {
  int get totalCourse => courses.length;
  int get completedCourse => courses.where((course) => course.isCompleted).length;
}