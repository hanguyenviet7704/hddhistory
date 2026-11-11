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

    final match = questionRuntimeOptions(question).firstWhere(
      (option) => option.id == answer.id,
      orElse: () => const OptionEntity(),
    );

    final matchText = match.text.text;
    if (matchText.isNotEmpty) return matchText;
    return match.value.text;
  }

  List<String> get currentOrderLabels => currentItems.map((item) => _optionLabel(item)).toList();

  List<String> get correctOrderLabels => questionRuntimeAnswers(question).map((answer) => _answerLabel(answer)).toList();

  /// 1-based position the item currently sitting at [index] SHOULD occupy.
  ///
  /// A graded row shows this number (design) instead of a bare cross, so a
  /// misplaced step tells the reader where it belonged without them having to
  /// diff the whole list. Null when the item can't be matched against the
  /// answer key at all.
  int? correctPositionFor(int index) {
    if (index < 0 || index >= currentItems.length) return null;
    final position = correctOrderLabels.indexOf(_optionLabel(currentItems[index]));
    return position < 0 ? null : position + 1;
  }

  ArrangeAnswerState getItemState(int index) {
    if (!hasChecked) return ArrangeAnswerState.normal;
    final runtimeAnswers = questionRuntimeAnswers(question);
    if (index >= currentItems.length || index >= runtimeAnswers.length) {
      return ArrangeAnswerState.incorrect;
    }

    final currentLabel = _optionLabel(currentItems[index]);
    final correctLabel = _answerLabel(runtimeAnswers[index]);

    return currentLabel == correctLabel ? ArrangeAnswerState.correct : ArrangeAnswerState.incorrect;
  }
}
