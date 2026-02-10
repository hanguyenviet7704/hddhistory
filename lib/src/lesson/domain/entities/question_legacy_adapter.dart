part of '../../lesson.dart';

/// Transitional compatibility adapter while legacy question fields are being retired.
///
/// Keep `payloadOrLegacy` until all persisted/constructed legacy-only questions
/// are migrated to provide `typedPayload` directly.
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
