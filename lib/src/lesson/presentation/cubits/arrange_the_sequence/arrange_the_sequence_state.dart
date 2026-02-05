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
  String _optionLabel(OptionEntity option) {
    final text = option.text.text;
    if (text.isNotEmpty) return text;
    return option.value.text;
  }

  String _answerLabel(AnswerEntity answer) {
    final text = answer.correctAnswer.text;
    if (text.isNotEmpty) return text;

    final match = question.options.firstWhere(
      (option) => option.id == answer.id,
      orElse: () => const OptionEntity(),
    );

    final matchText = match.text.text;
    if (matchText.isNotEmpty) return matchText;
    return match.value.text;
  }

  List<String> get currentOrderLabels => currentItems.map((item) => _optionLabel(item)).toList();

  List<String> get correctOrderLabels => question.answer.map((answer) => _answerLabel(answer)).toList();

  ArrangeAnswerState getItemState(int index) {
    if (!hasChecked) return ArrangeAnswerState.normal;
    if (index >= currentItems.length || index >= question.answer.length) {
      return ArrangeAnswerState.incorrect;
    }

    final currentLabel = _optionLabel(currentItems[index]);
    final correctLabel = _answerLabel(question.answer[index]);

    return currentLabel == correctLabel ? ArrangeAnswerState.correct : ArrangeAnswerState.incorrect;
  }
}
