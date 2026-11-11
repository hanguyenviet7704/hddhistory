part of '../../lesson.dart';

/// Runtime payload accessors for presentation.
///
/// These helpers read from typed payload only.
List<OptionEntity> questionRuntimeOptions(QuestionEntity question) {
  final payload = question.typedPayload;
  return switch (payload) {
    QuestionSingleChoicePayloadEntity(:final options) => options.map(_optionFromChoicePayload).toList(),
    QuestionMultipleChoicePayloadEntity(:final options) => options.map(_optionFromChoicePayload).toList(),
    QuestionSingleChoiceNoCorrectAnswerPayloadEntity(:final options) => options.map(_optionFromNoCorrectChoicePayload).toList(),
    QuestionDragAndDropPayloadEntity(:final options) => options.map(_optionFromDragDropPayload).toList(),
    QuestionArrangeTheSequencePayloadEntity(:final options) => options.map(_optionFromDragDropPayload).toList(),
    QuestionCuesPlacementPayloadEntity(:final options) => options.map(_optionFromDragDropPayload).toList(),
    QuestionStressPlacementPayloadEntity(:final options) => options.map(_optionFromDragDropPayload).toList(),
    QuestionSpeakingPayloadEntity() || QuestionUnsupportedPayloadEntity() => const [],
    _ => const [],
  };
}

List<AnswerEntity> questionRuntimeAnswers(QuestionEntity question) {
  final payload = question.typedPayload;
  return switch (payload) {
    QuestionDragAndDropPayloadEntity(:final answers) => answers.map(_answerFromDragDropPayload).toList(),
    QuestionArrangeTheSequencePayloadEntity(:final answers) => answers.map(_answerFromDragDropPayload).toList(),
    QuestionCuesPlacementPayloadEntity(:final answers) => answers.map(_answerFromDragDropPayload).toList(),
    QuestionStressPlacementPayloadEntity(:final answers) => answers.map(_answerFromDragDropPayload).toList(),
    _ => const [],
  };
}

BaseMultiLanguage questionRuntimeTargetArea(QuestionEntity question) {
  final payload = question.typedPayload;
  return switch (payload) {
    QuestionDragAndDropPayloadEntity(:final targetArea) => targetArea,
    QuestionCuesPlacementPayloadEntity(:final targetArea) => targetArea,
    QuestionStressPlacementPayloadEntity(:final targetArea) => targetArea,
    _ => const BaseMultiLanguage(),
  };
}

String questionRuntimeRecord(QuestionEntity question) {
  final payload = question.typedPayload;
  return switch (payload) {
    QuestionSpeakingPayloadEntity(:final record) => record,
    _ => '',
  };
}

List<ScoringCriteriaEntity> questionRuntimeScoringCriteria(QuestionEntity question) {
  final payload = question.typedPayload;
  return switch (payload) {
    QuestionSpeakingPayloadEntity(:final scoringCriteria) => scoringCriteria,
    _ => const [],
  };
}

OptionEntity _optionFromChoicePayload(QuestionChoiceOptionEntity option) {
  return OptionEntity(
    text: option.value,
    value: option.value,
    isCorrect: option.isCorrect,
  );
}

OptionEntity _optionFromNoCorrectChoicePayload(QuestionNoCorrectChoiceOptionEntity option) {
  return OptionEntity(
    text: option.value,
    value: option.value,
    isCorrect: false,
  );
}

OptionEntity _optionFromDragDropPayload(QuestionDragDropOptionEntity option) {
  return OptionEntity(
    id: option.id,
    text: option.text,
    value: option.text,
    isCorrect: false,
  );
}

AnswerEntity _answerFromDragDropPayload(QuestionDragDropAnswerEntity answer) {
  return AnswerEntity(
    id: answer.id,
    correctAnswer: answer.correctAnswer,
  );
}
