part of '../../../lesson.dart';

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
  List<AnswerEntity> get runtimeAnswers => questionRuntimeAnswers(question);

  /// Check if all drop zones are filled
  bool get isAllFilled {
    final requiredSlots = dropZoneCount;
    if (requiredSlots == 0) return false;
    for (int i = 0; i < requiredSlots; i++) {
      if (!placedWords.containsKey(i) || placedWords[i] == null || placedWords[i]!.isEmpty) {
        return false;
      }
    }
    return true;
  }

  /// Get the number of drop zones based on answer count
  int get dropZoneCount {
    final answerCount = runtimeAnswers.length;
    if (answerCount == 0) return 0;

    final blankCount = questionRuntimeTargetArea(question).text.split('___').length - 1;
    if (blankCount <= 0) return answerCount;

    return math.min(answerCount, blankCount);
  }

  /// Get the slot state for a specific index
  SlotState getSlotState(int index) {
    if (!hasChecked) return SlotState.normal;

    final placedAnswer = placedWords[index];
    if (placedAnswer == null || placedAnswer.isEmpty) return SlotState.normal;

    final correctAnswer = runtimeAnswers[index].correctAnswer;
    return placedAnswer == correctAnswer.text ? SlotState.correct : SlotState.incorrect;
  }
}

enum SlotState { normal, correct, incorrect }
