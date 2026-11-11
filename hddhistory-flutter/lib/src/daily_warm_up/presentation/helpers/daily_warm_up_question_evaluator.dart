part of '../../daily_warm_up.dart';

DailyWarmUpAnswerResultEntity evaluateDailyWarmUpQuestion(
  QuestionEntity question, {
  int questionIndex = 0,
  int selectedAnswerIndex = -1,
  Set<int> selectedAnswersIndices = const {},
  List<int> orderedOptionIds = const [],
  Map<int, int> placedOptionIds = const {},
  Set<int> selectedWordIndices = const {},
}) {
  final payload = question.typedPayload;
  return switch (payload) {
    QuestionSingleChoicePayloadEntity(:final options) => _evaluateChoice(
      question,
      questionIndex: questionIndex,
      options: options,
      selectedAnswerIndex: selectedAnswerIndex,
      selectedAnswersIndices: const {},
      isMultiple: false,
      isNeutral: false,
    ),
    QuestionMultipleChoicePayloadEntity(:final options) => _evaluateChoice(
      question,
      questionIndex: questionIndex,
      options: options,
      selectedAnswerIndex: -1,
      selectedAnswersIndices: selectedAnswersIndices,
      isMultiple: true,
      isNeutral: false,
    ),
    QuestionSingleChoiceNoCorrectAnswerPayloadEntity(:final options) => _evaluateNoCorrectChoice(
      question,
      questionIndex: questionIndex,
      optionsLength: options.length,
      selectedAnswerIndex: selectedAnswerIndex,
    ),
    QuestionDragAndDropPayloadEntity(:final answers, :final options) => _evaluateOrderedIds(
      question,
      questionIndex: questionIndex,
      answers: answers,
      options: options,
      orderedOptionIds: _orderedIdsFromSlots(placedOptionIds),
    ),
    QuestionArrangeTheSequencePayloadEntity(:final answers, :final options) => _evaluateOrderedIds(
      question,
      questionIndex: questionIndex,
      answers: answers,
      options: options,
      orderedOptionIds: orderedOptionIds,
    ),
    QuestionCuesPlacementPayloadEntity(:final answers) => _evaluatePositions(
      question,
      questionIndex: questionIndex,
      answers: answers,
      selectedPositions: placedOptionIds.keys.toSet(),
    ),
    QuestionStressPlacementPayloadEntity(:final answers) => _evaluatePositions(
      question,
      questionIndex: questionIndex,
      answers: answers,
      selectedPositions: selectedWordIndices,
    ),
    _ => _unsupported(question, questionIndex),
  };
}

DailyWarmUpAnswerResultEntity _evaluateChoice(
  QuestionEntity question, {
  required int questionIndex,
  required List<QuestionChoiceOptionEntity> options,
  required int selectedAnswerIndex,
  required Set<int> selectedAnswersIndices,
  required bool isMultiple,
  required bool isNeutral,
}) {
  final correctIndices = <int>{};
  for (var i = 0; i < options.length; i++) {
    if (options[i].isCorrect) correctIndices.add(i);
  }

  final selectedIndices = isMultiple
      ? selectedAnswersIndices.where((index) => index >= 0 && index < options.length).toSet()
      : selectedAnswerIndex >= 0 && selectedAnswerIndex < options.length
      ? {selectedAnswerIndex}
      : <int>{};

  final isCorrect = isNeutral || (selectedIndices.length == correctIndices.length && selectedIndices.containsAll(correctIndices));
  return _result(
    question,
    questionIndex: questionIndex,
    type: isNeutral
        ? DailyWarmUpAnswerResultType.neutral
        : isCorrect
        ? DailyWarmUpAnswerResultType.correct
        : DailyWarmUpAnswerResultType.incorrect,
    isCorrect: isCorrect,
    selectedIndices: selectedIndices.toList()..sort(),
    correctIndices: correctIndices.toList()..sort(),
  );
}

DailyWarmUpAnswerResultEntity _evaluateNoCorrectChoice(
  QuestionEntity question, {
  required int questionIndex,
  required int optionsLength,
  required int selectedAnswerIndex,
}) {
  final selected = selectedAnswerIndex >= 0 && selectedAnswerIndex < optionsLength ? [selectedAnswerIndex] : <int>[];
  return _result(
    question,
    questionIndex: questionIndex,
    type: selected.isEmpty ? DailyWarmUpAnswerResultType.unsupported : DailyWarmUpAnswerResultType.neutral,
    isCorrect: selected.isNotEmpty,
    selectedIndices: selected,
    correctIndices: selected,
  );
}

DailyWarmUpAnswerResultEntity _evaluateOrderedIds(
  QuestionEntity question, {
  required int questionIndex,
  required List<QuestionDragDropAnswerEntity> answers,
  required List<QuestionDragDropOptionEntity> options,
  required List<int> orderedOptionIds,
}) {
  final correctIds = _correctOrderedOptionIds(answers: answers, options: options);
  final isCorrect = correctIds.isNotEmpty && _sameOrderedInts(orderedOptionIds, correctIds);
  return _result(
    question,
    questionIndex: questionIndex,
    type: isCorrect ? DailyWarmUpAnswerResultType.correct : DailyWarmUpAnswerResultType.incorrect,
    isCorrect: isCorrect,
    selectedOptionIds: orderedOptionIds,
    correctOptionIds: correctIds,
  );
}

DailyWarmUpAnswerResultEntity _evaluatePositions(
  QuestionEntity question, {
  required int questionIndex,
  required List<QuestionDragDropAnswerEntity> answers,
  required Set<int> selectedPositions,
}) {
  final correctPositions = answers.map((answer) => int.tryParse(answer.correctAnswer.text) ?? 0).where((position) => position > 0).map((position) => position - 1).toSet();
  final isCorrect = correctPositions.isNotEmpty && selectedPositions.length == correctPositions.length && selectedPositions.containsAll(correctPositions);
  return _result(
    question,
    questionIndex: questionIndex,
    type: isCorrect ? DailyWarmUpAnswerResultType.correct : DailyWarmUpAnswerResultType.incorrect,
    isCorrect: isCorrect,
    selectedIndices: selectedPositions.toList()..sort(),
    correctIndices: correctPositions.toList()..sort(),
  );
}

DailyWarmUpAnswerResultEntity _unsupported(QuestionEntity question, int questionIndex) {
  return _result(
    question,
    questionIndex: questionIndex,
    type: DailyWarmUpAnswerResultType.unsupported,
    isCorrect: false,
  );
}

DailyWarmUpAnswerResultEntity _result(
  QuestionEntity question, {
  required int questionIndex,
  required DailyWarmUpAnswerResultType type,
  required bool isCorrect,
  List<int> selectedIndices = const [],
  List<int> correctIndices = const [],
  List<int> selectedOptionIds = const [],
  List<int> correctOptionIds = const [],
}) {
  return DailyWarmUpAnswerResultEntity(
    questionId: question.id,
    questionIndex: questionIndex,
    questionType: question.type,
    questionForm: question.form,
    type: type,
    isCorrect: isCorrect,
    selectedIndices: selectedIndices,
    correctIndices: correctIndices,
    selectedOptionIds: selectedOptionIds,
    correctOptionIds: correctOptionIds,
  );
}

List<int> _orderedIdsFromSlots(Map<int, int> placedOptionIds) {
  final entries = placedOptionIds.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
  return entries.map((entry) => entry.value).toList(growable: false);
}

bool _sameOrderedInts(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

List<int> _correctOrderedOptionIds({
  required List<QuestionDragDropAnswerEntity> answers,
  required List<QuestionDragDropOptionEntity> options,
}) {
  final optionIds = options.map((option) => option.id).where((id) => id != 0).toSet();
  final ids = <int>[];

  for (final answer in answers) {
    if (answer.id != 0 && optionIds.contains(answer.id)) {
      ids.add(answer.id);
      continue;
    }

    final label = answer.correctAnswer.text.trim();
    if (label.isEmpty) return const [];
    final matches = options.where((option) => option.text.text.trim() == label && option.id != 0).toList();
    if (matches.length != 1) return const [];
    ids.add(matches.single.id);
  }

  return ids;
}
