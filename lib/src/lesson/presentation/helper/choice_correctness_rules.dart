part of '../../lesson.dart';

bool resolveChoiceCheckResult({
  required bool isMultipleChoice,
  required bool isNoCorrectSingleChoice,
  required int selectedAnswerIndex,
  required Set<int> selectedAnswersIndices,
  required Set<int> correctOptionsIndices,
}) {
  if (isMultipleChoice) {
    if (selectedAnswersIndices.isEmpty) return false;
    return correctOptionsIndices.every((index) => selectedAnswersIndices.contains(index));
  }

  if (isNoCorrectSingleChoice) {
    return selectedAnswerIndex >= 0;
  }

  return correctOptionsIndices.contains(selectedAnswerIndex);
}

bool choiceIsMultipleCorrect(QuestionEntity question, Set<int> selectedIndices) {
  if (selectedIndices.isEmpty) return false;

  final options = questionRuntimeOptions(question);
  final correctIndices = <int>{};
  for (int i = 0; i < options.length; i++) {
    if (options[i].isCorrect) correctIndices.add(i);
  }

  return correctIndices.every((index) => selectedIndices.contains(index));
}

bool choiceIsSingleCorrect(QuestionEntity question, int selectedIndex) {
  if (selectedIndex < 0) return false;
  if (question.payloadOrLegacy is QuestionSingleChoiceNoCorrectAnswerPayloadEntity) return true;

  final options = questionRuntimeOptions(question);
  final correctIndex = options.indexWhere((option) => option.isCorrect);
  if (correctIndex == -1) return false;

  return selectedIndex == correctIndex;
}
