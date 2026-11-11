part of '../../daily_warm_up.dart';

AnswerState dailyWarmUpChoiceAnswerState({
  required QuestionEntity question,
  required int index,
  required int selectedAnswerIndex,
  required Set<int> selectedAnswersIndices,
  DailyWarmUpAnswerResultEntity? result,
}) {
  final isMultiple = question.typedPayload is QuestionMultipleChoicePayloadEntity;
  final isNoCorrect = question.typedPayload is QuestionSingleChoiceNoCorrectAnswerPayloadEntity;
  final wasSelected = isMultiple ? selectedAnswersIndices.contains(index) : selectedAnswerIndex == index;

  if (result == null) {
    return wasSelected ? AnswerState.selected : AnswerState.normal;
  }

  if (isNoCorrect) {
    return wasSelected ? AnswerState.correct : AnswerState.disabled;
  }

  final isCorrectOption = result.correctIndices.contains(index);
  if (isCorrectOption && isMultiple && !wasSelected) return AnswerState.correctNotSelected;
  if (isCorrectOption) return AnswerState.correct;
  if (wasSelected) return AnswerState.incorrect;
  return AnswerState.disabled;
}
