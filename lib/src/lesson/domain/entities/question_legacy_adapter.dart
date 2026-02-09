part of '../../lesson.dart';

extension QuestionLegacyAdapterX on QuestionEntity {
  /// Returns typed payload if already set; otherwise derives it from legacy fields.
  QuestionPayloadEntity get payloadOrLegacy {
    const defaultPayload = QuestionPayloadEntity.singleChoice();
    if (typedPayload != defaultPayload) return typedPayload;
    if (_hasLegacyPayloadData || type != QuestionTypeEnum.singleChoice) {
      return inferTypedPayloadFromLegacy();
    }
    return typedPayload;
  }

  bool get _hasLegacyPayloadData {
    if (options.isNotEmpty || answer.isNotEmpty) return true;
    if (targetArea.text.isNotEmpty) return true;
    if (record.isNotEmpty) return true;
    if (maxDuration > 0 || maxCharacter > 0) return true;
    return scoringCriteria.isNotEmpty;
  }

  QuestionPayloadEntity inferTypedPayloadFromLegacy() {
    return switch (type) {
      QuestionTypeEnum.singleChoice => QuestionPayloadEntity.singleChoice(
        options: options.map(_legacyChoiceOptionFromOption).toList(),
      ),
      QuestionTypeEnum.multipleChoice => QuestionPayloadEntity.multipleChoice(
        options: options.map(_legacyChoiceOptionFromOption).toList(),
      ),
      QuestionTypeEnum.dragAndDrop => QuestionPayloadEntity.dragAndDrop(
        targetArea: targetArea,
        answers: answer.map(_legacyDragDropAnswerFromAnswer).toList(),
        options: options.map(_legacyDragDropOptionFromOption).toList(),
      ),
      QuestionTypeEnum.arrangeTheSequence => QuestionPayloadEntity.arrangeTheSequence(
        answers: answer.map(_legacyDragDropAnswerFromAnswer).toList(),
        options: options.map(_legacyDragDropOptionFromOption).toList(),
      ),
      QuestionTypeEnum.cuesPlacement => QuestionPayloadEntity.cuesPlacement(
        targetArea: targetArea,
        answers: answer.map(_legacyDragDropAnswerFromAnswer).toList(),
        options: options.map(_legacyDragDropOptionFromOption).toList(),
      ),
      QuestionTypeEnum.stressPlacement => QuestionPayloadEntity.stressPlacement(
        targetArea: targetArea,
        answers: answer.map(_legacyDragDropAnswerFromAnswer).toList(),
        options: options.map(_legacyDragDropOptionFromOption).toList(),
      ),
      QuestionTypeEnum.speaking => QuestionPayloadEntity.speaking(
        record: record,
        maxDuration: maxDuration,
        maxCharacter: maxCharacter,
        scoringCriteria: scoringCriteria,
      ),
    };
  }

  QuestionEntity withInferredTypedPayload() => copyWith(typedPayload: inferTypedPayloadFromLegacy());

  List<OptionEntity> get legacyOptionsFromPayload {
    final payload = payloadOrLegacy;
    return switch (payload) {
      QuestionSingleChoicePayloadEntity(:final options) => options.map(_legacyOptionFromChoiceOption).toList(),
      QuestionMultipleChoicePayloadEntity(:final options) => options.map(_legacyOptionFromChoiceOption).toList(),
      QuestionSingleChoiceNoCorrectAnswerPayloadEntity(:final options) => options.map(_legacyOptionFromNoCorrectOption).toList(),
      QuestionDragAndDropPayloadEntity(:final options) => options.map(_legacyOptionFromDragDropOption).toList(),
      QuestionArrangeTheSequencePayloadEntity(:final options) => options.map(_legacyOptionFromDragDropOption).toList(),
      QuestionCuesPlacementPayloadEntity(:final options) => options.map(_legacyOptionFromDragDropOption).toList(),
      QuestionStressPlacementPayloadEntity(:final options) => options.map(_legacyOptionFromDragDropOption).toList(),
      QuestionSpeakingPayloadEntity() => const [],
      QuestionUnsupportedPayloadEntity() => const [],
      _ => const [],
    };
  }

  List<AnswerEntity> get legacyAnswersFromPayload {
    final payload = payloadOrLegacy;
    return switch (payload) {
      QuestionDragAndDropPayloadEntity(:final answers) => answers.map(_legacyAnswerFromDragDropAnswer).toList(),
      QuestionArrangeTheSequencePayloadEntity(:final answers) => answers.map(_legacyAnswerFromDragDropAnswer).toList(),
      QuestionCuesPlacementPayloadEntity(:final answers) => answers.map(_legacyAnswerFromDragDropAnswer).toList(),
      QuestionStressPlacementPayloadEntity(:final answers) => answers.map(_legacyAnswerFromDragDropAnswer).toList(),
      _ => const [],
    };
  }

  BaseMultiLanguage get legacyTargetAreaFromPayload {
    final payload = payloadOrLegacy;
    return switch (payload) {
      QuestionDragAndDropPayloadEntity(:final targetArea) => targetArea,
      QuestionCuesPlacementPayloadEntity(:final targetArea) => targetArea,
      QuestionStressPlacementPayloadEntity(:final targetArea) => targetArea,
      _ => const BaseMultiLanguage(),
    };
  }

  String get legacyRecordFromPayload {
    final payload = payloadOrLegacy;
    return switch (payload) {
      QuestionSpeakingPayloadEntity(:final record) => record,
      _ => '',
    };
  }

  List<ScoringCriteriaEntity> get legacyScoringCriteriaFromPayload {
    final payload = payloadOrLegacy;
    return switch (payload) {
      QuestionSpeakingPayloadEntity(:final scoringCriteria) => scoringCriteria,
      _ => const [],
    };
  }
}

QuestionChoiceOptionEntity _legacyChoiceOptionFromOption(OptionEntity option) {
  final pickedValue = option.value.text.isNotEmpty ? option.value : option.text;
  return QuestionChoiceOptionEntity(
    value: pickedValue,
    isCorrect: option.isCorrect,
  );
}

QuestionDragDropOptionEntity _legacyDragDropOptionFromOption(OptionEntity option) {
  final pickedText = option.text.text.isNotEmpty ? option.text : option.value;
  return QuestionDragDropOptionEntity(
    id: option.id,
    text: pickedText,
  );
}

QuestionDragDropAnswerEntity _legacyDragDropAnswerFromAnswer(AnswerEntity answer) {
  return QuestionDragDropAnswerEntity(
    id: answer.id,
    correctAnswer: answer.correctAnswer,
  );
}

OptionEntity _legacyOptionFromChoiceOption(QuestionChoiceOptionEntity option) {
  return OptionEntity(
    text: option.value,
    value: option.value,
    isCorrect: option.isCorrect,
  );
}

OptionEntity _legacyOptionFromDragDropOption(QuestionDragDropOptionEntity option) {
  return OptionEntity(
    id: option.id,
    text: option.text,
    value: option.text,
  );
}

OptionEntity _legacyOptionFromNoCorrectOption(QuestionNoCorrectChoiceOptionEntity option) {
  return OptionEntity(
    text: option.value,
    value: option.value,
    isCorrect: false,
  );
}

AnswerEntity _legacyAnswerFromDragDropAnswer(QuestionDragDropAnswerEntity answer) {
  return AnswerEntity(
    id: answer.id,
    correctAnswer: answer.correctAnswer,
  );
}
