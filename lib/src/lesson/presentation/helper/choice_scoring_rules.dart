part of '../../lesson.dart';

int calculateChoiceScore({
  required bool isMultipleChoice,
  required bool isNoCorrectSingleChoice,
  required int maxScore,
  required Set<int> correctOptionsIndices,
  required Set<int> selectedAnswersIndices,
  required int selectedAnswerIndex,
}) {
  if (isMultipleChoice) {
    if (selectedAnswersIndices.isEmpty) return 0;

    final correctCount = correctOptionsIndices.length;
    if (correctCount == 0) return 0;

    final pointPerCorrect = maxScore / correctCount;
    final correctSelections = selectedAnswersIndices.where((index) => correctOptionsIndices.contains(index)).length;
    final wrongSelections = selectedAnswersIndices.where((index) => !correctOptionsIndices.contains(index)).length;
    final score = (correctSelections * pointPerCorrect) - (wrongSelections * pointPerCorrect * 0.5);
    return score.clamp(0, maxScore).toInt();
  }

  if (isNoCorrectSingleChoice) {
    return selectedAnswerIndex >= 0 ? maxScore : 0;
  }

  if (correctOptionsIndices.isEmpty) return 0;
  final correctIndex = correctOptionsIndices.first;
  return selectedAnswerIndex == correctIndex ? maxScore : 0;
}
