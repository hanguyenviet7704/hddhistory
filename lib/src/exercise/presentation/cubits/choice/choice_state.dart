part of '../../../exercise.dart';

enum ChoiceStatus { initial, loading, success, failure }
enum AnswerState { normal, selected, correct, incorrect, disabled }

@freezed
sealed class ChoiceState with _$ChoiceState {
  const factory ChoiceState({
    @Default(ChoiceStatus.initial) ChoiceStatus status,
    @Default(QuestionEntity()) QuestionEntity question,
    @Default(-1) int selectedAnswerIndex,
    @Default({}) Set<int> selectedAnswersIndices,
    @Default(false) bool hasChecked,
    @Default(false) bool isCorrect,
  }) = _ChoiceState;

  factory ChoiceState.initial() => const ChoiceState();
}

extension ChoiceStateExtension on ChoiceState {
  List<OptionEntity> get answerOptions => question.options;
  Set<int> get correctOptionsIndices => question.options.where((option) => option.isCorrect).map((option) => option.id).toSet();

  AnswerState getAnswerState(int index) {
    if (!hasChecked) {
      return selectedAnswerIndex == index ? AnswerState.selected : AnswerState.normal;
    }

    if (question.id == 0) return AnswerState.normal;

    if (correctOptionsIndices.contains(index)) {
      return AnswerState.correct;
    }

    if (selectedAnswerIndex == index) {
      return AnswerState.incorrect;
    }

    return AnswerState.disabled;
  }
}
