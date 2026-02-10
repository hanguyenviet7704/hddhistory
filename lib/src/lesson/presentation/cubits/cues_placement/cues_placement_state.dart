part of '../../../lesson.dart';

enum CuesPlacementStatus { initial, loading, success, failure }

@freezed
sealed class CuesPlacementState with _$CuesPlacementState {
  const factory CuesPlacementState({
    @Default(CuesPlacementStatus.initial) CuesPlacementStatus status,
    @Default(QuestionEntity()) QuestionEntity question,
    @Default({}) Map<int, int> placedMarks, // word index (0-based) -> option id
    @Default(false) bool hasChecked,
    @Default(false) bool isCorrect,
    @Default(false) bool showExplanation,
  }) = _CuesPlacementState;

  factory CuesPlacementState.initial() => const CuesPlacementState();
}

extension CuesPlacementStateX on CuesPlacementState {
  /// Get list of words by splitting targetArea by space
  List<String> get words => questionRuntimeTargetArea(question).text.split(' ');

  /// Get total number of pause marks available
  int get totalMarksCount => questionRuntimeOptions(question).length;

  /// Get number of available (not yet placed) pause marks
  int get availableMarksCount => totalMarksCount - placedMarks.length;

  /// Get set of correct positions (0-based indices where pause marks should be placed)
  /// The answer contains 1-based indices, so we subtract 1
  Set<int> get correctPositions {
    return questionRuntimeAnswers(question)
        .map((answer) => int.tryParse(answer.correctAnswer.text) ?? 0)
        .where((index) => index > 0)
        .map((index) => index - 1) // Convert from 1-based to 0-based
        .toSet();
  }

  /// Check if a pause mark is placed after the word at given index
  bool hasPauseMarkAfter(int wordIndex) {
    return placedMarks.containsKey(wordIndex);
  }

  /// Get the state of a pause mark position after a word
  /// Returns null if no mark, or the state (normal/correct/incorrect)
  AnswerState? getPauseMarkState(int wordIndex) {
    final hasMark = hasPauseMarkAfter(wordIndex);
    final shouldHaveMark = correctPositions.contains(wordIndex);

    if (!hasChecked) {
      return hasMark ? AnswerState.selected : null;
    }

    // After checking
    if (hasMark && shouldHaveMark) {
      return AnswerState.correct; // Correctly placed
    }

    if (hasMark && !shouldHaveMark) {
      return AnswerState.incorrect; // Incorrectly placed
    }

    if (!hasMark && shouldHaveMark) {
      return AnswerState.correctNotSelected; // Should have mark but doesn't
    }

    return null; // No mark and shouldn't have one
  }

  /// Get available pause mark options that haven't been placed yet
  List<OptionEntity> get availableOptions {
    final placedOptionIds = placedMarks.values.toSet();
    return questionRuntimeOptions(question).where((option) => !placedOptionIds.contains(option.id)).toList();
  }
}
