part of '../../progress.dart';

@freezed
abstract class LessonResultEntity with _$LessonResultEntity {
  const factory LessonResultEntity({
    @Default('') String lessonId,
    @Default(0.0) double averageScore,
    @Default(false) bool passed,
    @Default([]) List<KeypointResultEntity> keypointsResult,
    @Default('') String reviews,
    DateTime? submittedAt,
  }) = _LessonResultEntity;

  factory LessonResultEntity.fromJson(Map<String, dynamic> json) => _$LessonResultEntityFromJson(json);
}

extension LessonResultEntityExtension on LessonResultEntity {
  List<ExerciseResultEntity> get exercisesResult => keypointsResult.expand((keypoint) => keypoint.exercisesResult).toList();
}
