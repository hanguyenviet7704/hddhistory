part of '../../../exercise.dart';

enum DragAndDropStatus { initial, loading, success, failure }

@freezed
abstract class DragAndDropState with _$DragAndDropState {
  const factory DragAndDropState({
    @Default(DragAndDropStatus.initial) DragAndDropStatus status,
    @Default(QuestionEntity()) QuestionEntity question,
    @Default([]) List<String> availableWords,
    @Default({}) Map<int, String> placedWords,
    @Default(false) bool hasChecked,
    @Default(false) bool isCorrect,
    @Default(false) bool showExplanation,
  }) = _DragAndDropState;

  factory DragAndDropState.initial() => const DragAndDropState();
}

extension DragAndDropStateExtension on DragAndDropState {
  /// Check if all drop zones are filled
  bool get isAllFilled {
    if (question.answer.isEmpty) return false;
    for (int i = 0; i < question.answer.length; i++) {
      if (!placedWords.containsKey(i) || placedWords[i] == null || placedWords[i]!.isEmpty) {
        return false;
      }
    }
    return true;
  }

  /// Get the number of drop zones based on answer count
  int get dropZoneCount => question.answer.length;
}
