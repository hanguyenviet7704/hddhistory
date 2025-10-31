part of '../../../lesson.dart';

enum ExerciseStatus { initial, loading, success, failure }

@freezed
abstract class ExerciseState with _$ExerciseState {
  const factory ExerciseState({
    @Default(ExerciseStatus.initial) ExerciseStatus status,
    @Default(LearningItemEntity()) LearningItemEntity currentLearningItem,
    @Default(0) int currentQuestionIndex,
    String? errorMessage,
  }) = _ExerciseState;

  factory ExerciseState.initial() => ExerciseState();

  factory ExerciseState.fromJson(Map<String, dynamic> json) => _$ExerciseStateFromJson(json);
}

extension ExerciseStateExtension on ExerciseState {
  QuestionEntity get currentQuestion {
    return currentLearningItem.questions.elementAtOrDefault(currentQuestionIndex, defaultValue: QuestionEntity());
  }

  double get progress {
    if (currentQuestionIndex == 0 || currentLearningItem.questions.isEmpty) return 0;
    if (currentQuestionIndex == currentLearningItem.questions.length) return 1;
    return (currentQuestionIndex + 1) / currentLearningItem.questions.length;
  }
}