part of '../../progress.dart';

@freezed
abstract class KeypointResultEntity with _$KeypointResultEntity {
  const factory KeypointResultEntity({
    @Default('') String keypointId,
    @Default(0.0) double averageScore,
    @Default(false) bool passed,
    @Default([]) List<ExerciseResultEntity> exercisesResult,
    @Default('') String reviews,
    DateTime? submittedAt,
  }) = _KeypointResultEntity;

  factory KeypointResultEntity.fromJson(Map<String, dynamic> json) => _$KeypointResultEntityFromJson(json);
}

