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
  QuestionPayloadEntity get payload => question.typedPayload;

  bool get isMultipleChoiceQuestion => payload is QuestionMultipleChoicePayloadEntity;

  bool get isNoCorrectSingleChoiceQuestion => payload is QuestionSingleChoiceNoCorrectAnswerPayloadEntity;

  List<OptionEntity> get answerOptions => questionRuntimeOptions(question);

  /// Returns the list indices of correct options (not option IDs)
  Set<int> get correctOptionsIndices {
    if (isNoCorrectSingleChoiceQuestion) {
      if (selectedAnswerIndex < 0 || selectedAnswerIndex >= answerOptions.length) return {};
      return {selectedAnswerIndex};
    }

    final Set<int> indices = {};
    for (int i = 0; i < answerOptions.length; i++) {
      if (answerOptions[i].isCorrect) {
        indices.add(i);
      }
    }
    return indices;
  }

  AnswerState getAnswerState(int index) {
    // Before checking answer, show selected state
    if (!hasChecked) {
      if (isMultipleChoiceQuestion) {
        return selectedAnswersIndices.contains(index) ? AnswerState.selected : AnswerState.normal;
      } else {
        return selectedAnswerIndex == index ? AnswerState.selected : AnswerState.normal;
      }
    }

    // After checking, show correct/incorrect states
    if (question.id == 0) return AnswerState.normal;

    if (isNoCorrectSingleChoiceQuestion) {
      return selectedAnswerIndex == index ? AnswerState.correct : AnswerState.disabled;
    }

    final bool isCorrectOption = correctOptionsIndices.contains(index);
    final bool wasSelected = isMultipleChoiceQuestion ? selectedAnswersIndices.contains(index) : selectedAnswerIndex == index;

    // Show correct answers
    if (isCorrectOption) {
      // For multiple choice, distinguish between selected and not selected correct answers
      if (isMultipleChoiceQuestion && !wasSelected) {
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
