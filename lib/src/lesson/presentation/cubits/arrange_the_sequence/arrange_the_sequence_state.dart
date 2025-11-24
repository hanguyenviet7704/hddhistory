part of '../../../lesson.dart';

enum ArrangeTheSequenceStatus { initial, loading, success, failure }

enum ArrangeAnswerState { normal, correct, incorrect }

@freezed
sealed class ArrangeTheSequenceState with _$ArrangeTheSequenceState {
  const factory ArrangeTheSequenceState({
    @Default(ArrangeTheSequenceStatus.initial) ArrangeTheSequenceStatus status,
    @Default(QuestionEntity()) QuestionEntity question,
    @Default([]) List<OptionEntity> currentItems,
    @Default(false) bool hasChecked,
    @Default(false) bool isCorrect,
    @Default(false) bool showExplanation,
  }) = _ArrangeTheSequenceState;

  factory ArrangeTheSequenceState.initial() => const ArrangeTheSequenceState();
}

extension ArrangeTheSequenceStateX on ArrangeTheSequenceState {
  List<int> get correctOrderIds => question.answer.map((answer) => answer.id).toList();

  ArrangeAnswerState getItemState(int index) {
    if (!hasChecked) return ArrangeAnswerState.normal;
    if (index >= currentItems.length || index >= correctOrderIds.length) {
      return ArrangeAnswerState.incorrect;
    }

    final currentId = currentItems[index].id;
    final correctId = correctOrderIds[index];

    return currentId == correctId ? ArrangeAnswerState.correct : ArrangeAnswerState.incorrect;
  }
}
