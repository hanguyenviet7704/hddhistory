part of '../../daily_warm_up.dart';

List<QuestionEntity> filterUsableDailyWarmUpQuestions(Iterable<QuestionEntity> questions) {
  return questions.where(isUsableDailyWarmUpQuestion).toList(growable: false);
}

bool isUsableDailyWarmUpQuestion(QuestionEntity question) {
  if (!_hasRenderableQuestion(question)) return false;
  if (question.type == QuestionTypeEnum.speaking) return false;

  final payload = question.typedPayload;
  return switch (payload) {
    QuestionSingleChoicePayloadEntity(:final options) => _hasChoiceOptions(options, requireCorrect: true),
    QuestionMultipleChoicePayloadEntity(:final options) => _hasChoiceOptions(options, requireCorrect: true),
    QuestionSingleChoiceNoCorrectAnswerPayloadEntity(:final options) => options.any((option) => _textOf(option.value).isNotEmpty),
    QuestionDragAndDropPayloadEntity(:final targetArea, :final answers, :final options) =>
      _textOf(targetArea).isNotEmpty && _hasDragOptions(options) && _hasUsableOrderedAnswers(answers, options),
    QuestionArrangeTheSequencePayloadEntity(:final answers, :final options) => _hasDragOptions(options) && _hasUsableOrderedAnswers(answers, options),
    QuestionCuesPlacementPayloadEntity(:final targetArea, :final answers, :final options) => _hasPositionPayload(targetArea: targetArea, answers: answers, options: options),
    QuestionStressPlacementPayloadEntity(:final targetArea, :final answers, :final options) => _hasPositionPayload(targetArea: targetArea, answers: answers, options: options),
    QuestionSpeakingPayloadEntity() || QuestionUnsupportedPayloadEntity() => false,
    _ => false,
  };
}

String dailyWarmUpQuestionTypeName(QuestionEntity question) {
  return switch (question.typedPayload) {
    QuestionSingleChoiceNoCorrectAnswerPayloadEntity() => QuestionType.singleChoiceNoCorrectAnswer.rawValue,
    QuestionDragAndDropPayloadEntity() => QuestionType.dragAndDrop.rawValue,
    _ => switch (question.type) {
      QuestionTypeEnum.singleChoice => QuestionType.singleChoice.rawValue,
      QuestionTypeEnum.multipleChoice => QuestionType.multipleChoice.rawValue,
      QuestionTypeEnum.dragAndDrop => QuestionType.dragAndDrop.rawValue,
      QuestionTypeEnum.arrangeTheSequence => 'arrange_the_sequence',
      QuestionTypeEnum.cuesPlacement => 'cues_placement',
      QuestionTypeEnum.stressPlacement => 'stress_placement',
      QuestionTypeEnum.speaking => 'speaking',
    },
  };
}

bool _hasRenderableQuestion(QuestionEntity question) {
  if (question.questionText.trim().isNotEmpty && question.questionText != 'No question text') return true;
  return question.speechBubble.text.trim().isNotEmpty;
}

bool _hasChoiceOptions(List<QuestionChoiceOptionEntity> options, {required bool requireCorrect}) {
  final visibleOptions = options.where((option) => _textOf(option.value).isNotEmpty).toList();
  if (visibleOptions.isEmpty) return false;
  if (!requireCorrect) return true;
  return visibleOptions.any((option) => option.isCorrect);
}

bool _hasDragOptions(List<QuestionDragDropOptionEntity> options) {
  return options.any((option) => option.id != 0 && _textOf(option.text).isNotEmpty);
}

bool _hasUsableOrderedAnswers(List<QuestionDragDropAnswerEntity> answers, List<QuestionDragDropOptionEntity> options) {
  if (answers.isEmpty) return false;
  final optionIds = options.map((option) => option.id).where((id) => id != 0).toSet();
  final optionLabelCounts = <String, int>{};
  for (final option in options) {
    final label = _textOf(option.text);
    if (label.isEmpty) continue;
    optionLabelCounts[label] = (optionLabelCounts[label] ?? 0) + 1;
  }

  return answers.every((answer) {
    if (answer.id != 0 && optionIds.contains(answer.id)) return true;
    final label = _textOf(answer.correctAnswer);
    return label.isNotEmpty && optionLabelCounts[label] == 1;
  });
}

bool _hasPositionPayload({
  required BaseMultiLanguage targetArea,
  required List<QuestionDragDropAnswerEntity> answers,
  required List<QuestionDragDropOptionEntity> options,
}) {
  final words = _targetWords(targetArea);
  if (words.isEmpty || answers.isEmpty || !_hasDragOptions(options)) return false;
  return answers.every((answer) {
    final position = int.tryParse(_textOf(answer.correctAnswer));
    return position != null && position > 0 && position <= words.length;
  });
}

List<String> _targetWords(BaseMultiLanguage targetArea) {
  return _textOf(targetArea).split(RegExp(r'\s+')).where((word) => word.trim().isNotEmpty).toList();
}

String _textOf(BaseMultiLanguage value) => value.text.trim();
