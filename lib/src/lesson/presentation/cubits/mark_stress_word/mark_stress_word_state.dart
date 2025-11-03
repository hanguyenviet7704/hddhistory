part of '../../../lesson.dart';

enum MarkStressWordStatus { initial, loading, success, failure }

@freezed
sealed class MarkStressWordState with _$MarkStressWordState {
  const factory MarkStressWordState({
    @Default(MarkStressWordStatus.initial) MarkStressWordStatus status,
    @Default(QuestionEntity()) QuestionEntity question,
    @Default({}) Set<int> selectedWordIndices,
    @Default(false) bool hasChecked,
    @Default(false) bool isCorrect,
    @Default(false) bool showExplanation,
  }) = _MarkStressWordState;

  factory MarkStressWordState.initial() => const MarkStressWordState();
}

extension MarkStressWordStateX on MarkStressWordState {
  /// Get list of words by splitting targetArea by space
  List<String> get words => question.targetArea.split(' ');

  /// Get set of correct word indices (0-based)
  /// The answer contains 1-based indices, so we subtract 1
  Set<int> get correctWordIndices {
    return question.answer
        .map((answer) => int.tryParse(answer.correctAnswer) ?? 0)
        .where((index) => index > 0)
        .map((index) => index - 1) // Convert from 1-based to 0-based
        .toSet();
  }

  /// Get the state of a word at given index
  AnswerState getWordState(int index) {
    final isSelected = selectedWordIndices.contains(index);
    final isCorrect = correctWordIndices.contains(index);

    if (!hasChecked) {
      return isSelected ? AnswerState.selected : AnswerState.normal;
    }

    // After checking
    if (isSelected && isCorrect) {
      return AnswerState.correct; // Selected and correct
    }

    if (isSelected && !isCorrect) {
      return AnswerState.incorrect; // Selected but wrong
    }

    if (!isSelected && isCorrect) {
      return AnswerState.correctNotSelected; // Correct but not selected
    }

    return AnswerState.disabled; // Not selected and not correct
  }
}
