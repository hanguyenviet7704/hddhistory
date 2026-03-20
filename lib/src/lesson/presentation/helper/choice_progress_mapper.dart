part of '../../lesson.dart';

QuestionType progressQuestionTypeFromPayload(QuestionPayloadEntity payload) {
  return switch (payload) {
    QuestionSingleChoiceNoCorrectAnswerPayloadEntity() => QuestionType.singleChoiceNoCorrectAnswer,
    QuestionMultipleChoicePayloadEntity() => QuestionType.multipleChoice,
    _ => QuestionType.singleChoice,
  };
}
