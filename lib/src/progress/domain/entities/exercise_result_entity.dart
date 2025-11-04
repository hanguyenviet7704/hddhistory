part of '../../progress.dart';

@freezed
abstract class ExerciseResultEntity with _$ExerciseResultEntity {
  const factory ExerciseResultEntity({
    @Default('') String exerciseId,
    @Default(0.0) double score,
    @Default(false) bool passed,
    @Default(0) int numberOfCorrect,
    @Default(0) int numberOfIncorrect,
    @Default('') String reviews,
    DateTime? submittedAt,
  }) = _ExerciseResultEntity;

  factory ExerciseResultEntity.fromJson(Map<String, dynamic> json) => _$ExerciseResultEntityFromJson(json);
}

