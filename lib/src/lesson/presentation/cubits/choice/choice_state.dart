part of '../../../lesson.dart';

enum ChoiceStatus { initial, loading, success, failure }
enum AnswerState { normal, selected, correct, incorrect, disabled, correctNotSelected }

@freezed
sealed class ChoiceState with _$ChoiceState {
  const factory ChoiceState({
    @Default(ChoiceStatus.initial) ChoiceStatus status,
    @Default(QuestionEntity()) QuestionEntity question,
    @Default(-1) int selectedAnswerIndex,
    @Default({}) Set<int> selectedAnswersIndices,
    @Default(false) bool hasChecked,
    @Default(false) bool isCorrect,
    @Default(false) bool showExplanation,
  }) = _ChoiceState;

  factory ChoiceState.initial() => const ChoiceState();
}

extension ChoiceStateExtension on ChoiceState {
  List<OptionEntity> get answerOptions => question.options;

  /// Returns the list indices of correct options (not option IDs)
  Set<int> get correctOptionsIndices {
    final Set<int> indices = {};
    for (int i = 0; i < question.options.length; i++) {
      if (question.options[i].isCorrect) {
        indices.add(i);
      }
    }
    return indices;
  }

  AnswerState getAnswerState(int index) {
    // Before checking answer, show selected state
    if (!hasChecked) {
      if (question.type == QuestionTypeEnum.multipleChoice) {
        return selectedAnswersIndices.contains(index) ? AnswerState.selected : AnswerState.normal;
      } else {
        return selectedAnswerIndex == index ? AnswerState.selected : AnswerState.normal;
      }
    }

    // After checking, show correct/incorrect states
    if (question.id == 0) return AnswerState.normal;

    final bool isCorrectOption = correctOptionsIndices.contains(index);
    final bool wasSelected = question.type == QuestionTypeEnum.multipleChoice
        ? selectedAnswersIndices.contains(index)
        : selectedAnswerIndex == index;

    // Show correct answers
    if (isCorrectOption) {
      // For multiple choice, distinguish between selected and not selected correct answers
      if (question.type == QuestionTypeEnum.multipleChoice && !wasSelected) {
        return AnswerState.correctNotSelected;
      }
      return AnswerState.correct;
    }

    // Show incorrect selected answers
    if (wasSelected) {
      return AnswerState.incorrect;
    }

    // Disable unselected wrong answers
    return AnswerState.disabled;
  }
}
