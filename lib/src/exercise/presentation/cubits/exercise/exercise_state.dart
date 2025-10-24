part of '../../../exercise.dart';

enum ExerciseStatus { initial, loading, success, failure }

@freezed
abstract class ExerciseState with _$ExerciseState {
  const factory ExerciseState({
    @Default(ExerciseStatus.initial) ExerciseStatus status,
    @Default(BasePageBreak<LearningItemEntity>()) BasePageBreak<LearningItemEntity> pageData,
    @Default(LearningItemEntity()) LearningItemEntity currentLearningItem,
    @Default(QuestionEntity()) QuestionEntity currentQuestion,
    String? errorMessage,
  }) = _ExerciseState;

  factory ExerciseState.initial() => ExerciseState();

  factory ExerciseState.fromJson(Map<String, dynamic> json) => _$ExerciseStateFromJson(json);
}
