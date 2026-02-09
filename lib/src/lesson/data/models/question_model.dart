part of '../../lesson.dart';

@freezed
abstract class QuestionModel with _$QuestionModel {
  const factory QuestionModel({
    @JsonKey(unknownEnumValue: QuestionType.unknown) @Default(QuestionType.singleChoice) QuestionType type,
    @Default(FormDragDropType.textGapFilling) FormDragDropType form,
    @Default(0) int id,
    @Default('') String exerciseId,
    @Default(BaseMultiLanguage()) BaseMultiLanguage speechBubble,
    @Default(TagModel()) TagModel tag,
    @Default([]) List<ContentDocumentModel> document,
    @Default(BaseMultiLanguage()) BaseMultiLanguage explanation,
    @Default(BaseMultiLanguage()) BaseMultiLanguage targetArea,
    @Default([]) List<AnswerModel> answer,
    @Default([]) List<OptionModel> options,
    @Default([]) List<NoCorrectDocumentGroupModel> documentGroups,
    @Default([]) List<KeypointLevelType> level,
    @Default('') String record,
    @Default(0) int maxDuration,
    @Default(0) int maxCharacter,
    @Default(0) int maxScore,
    @Default(0) int completionTime,
    @Default([]) List<ScoringCriteriaModel> scoringCriteria,
    @Default(0) int mainQuestion,
    @Default(KeypointModel()) KeypointModel keypoint,
  }) = _QuestionModel;

  factory QuestionModel.fromJson(Map<String, dynamic> json) => _$QuestionModelFromJson(json);
}

enum KeypointLevelType {
  @JsonValue('optional_practice')
  optionalPractice,
  @JsonValue('more_practice')
  morePractice,
  @JsonValue('weak_point')
  weakPoint,
}

enum QuestionType {
  @JsonValue('single_choice')
  singleChoice,
  @JsonValue('multiple_choice')
  multipleChoice,
  @JsonValue('single_choice_no_correct_answer')
  singleChoiceNoCorrectAnswer,
  @JsonValue('drag_drop')
  dragAndDrop,
  @JsonValue('record')
  record,
  @JsonValue('unknown')
  unknown;

  QuestionTypeEnum toQuestionTypeEnum(FormDragDropType form) {
    return switch (this) {
      QuestionType.singleChoice => QuestionTypeEnum.singleChoice,
      QuestionType.multipleChoice => QuestionTypeEnum.multipleChoice,
      QuestionType.singleChoiceNoCorrectAnswer => QuestionTypeEnum.singleChoice,
      QuestionType.record => QuestionTypeEnum.speaking,
      QuestionType.dragAndDrop => switch (form) {
        FormDragDropType.textGapFilling => QuestionTypeEnum.dragAndDrop,
        FormDragDropType.cuesPlacement => QuestionTypeEnum.cuesPlacement,
        FormDragDropType.stressPlacement => QuestionTypeEnum.stressPlacement,
        FormDragDropType.arrangeTheSequence => QuestionTypeEnum.arrangeTheSequence,
      },
      QuestionType.unknown => QuestionTypeEnum.singleChoice,
    };
  }

  String get rawValue {
    return switch (this) {
      QuestionType.singleChoice => 'single_choice',
      QuestionType.multipleChoice => 'multiple_choice',
      QuestionType.singleChoiceNoCorrectAnswer => 'single_choice_no_correct_answer',
      QuestionType.dragAndDrop => 'drag_drop',
      QuestionType.record => 'record',
      QuestionType.unknown => 'unknown',
    };
  }
}

enum FormDragDropType {
  @JsonValue('Text Gap Filling')
  textGapFilling,
  @JsonValue('Cues Placement')
  cuesPlacement,
  @JsonValue('Stress Placement')
  stressPlacement,
  @JsonValue('Arrange the Sequence')
  arrangeTheSequence,
}

extension QuestionModelExtension on QuestionModel {
  QuestionEntity toEntity() {
    final mappedAnswers = answer.map((model) => model.toEntity()).toList();
    final mappedOptions = options.map((model) => model.toEntity()).toList();
    final mappedScoringCriteria = scoringCriteria.map((model) => model.toEntity()).toList();

    return QuestionEntity(
      type: type.toQuestionTypeEnum(form),
      id: id,
      exerciseId: exerciseId,
      speechBubble: speechBubble,
      tag: tag.toEntity(),
      document: document.map((model) => model.toEntity()).toList(),
      explanation: explanation,
      targetArea: targetArea,
      answer: mappedAnswers,
      options: mappedOptions,
      level: level,
      form: form,
      record: record,
      maxDuration: maxDuration,
      maxCharacter: maxCharacter,
      maxScore: maxScore,
      completionTime: completionTime,
      scoringCriteria: mappedScoringCriteria,
      mainQuestion: mainQuestion,
      keypoint: keypoint.toEntity(),
      typedPayload: _toTypedPayload(mappedScoringCriteria),
    );
  }

  QuestionPayloadEntity _toTypedPayload(List<ScoringCriteriaEntity> mappedScoringCriteria) {
    return switch (type) {
      QuestionType.singleChoice => QuestionPayloadEntity.singleChoice(
        options: options.map((model) => model.toChoiceOptionEntity()).toList(),
      ),
      QuestionType.multipleChoice => QuestionPayloadEntity.multipleChoice(
        options: options.map((model) => model.toChoiceOptionEntity()).toList(),
      ),
      QuestionType.singleChoiceNoCorrectAnswer => QuestionPayloadEntity.singleChoiceNoCorrectAnswer(
        options: options.map((model) => model.toNoCorrectChoiceOptionEntity()).toList(),
        documentGroups: documentGroups.map((model) => model.toEntity()).toList(),
      ),
      QuestionType.dragAndDrop => switch (form) {
        FormDragDropType.textGapFilling => QuestionPayloadEntity.dragAndDrop(
          targetArea: targetArea,
          answers: answer.map((model) => model.toDragDropAnswerEntity()).toList(),
          options: options.map((model) => model.toDragDropOptionEntity()).toList(),
        ),
        FormDragDropType.cuesPlacement => QuestionPayloadEntity.cuesPlacement(
          targetArea: targetArea,
          answers: answer.map((model) => model.toDragDropAnswerEntity()).toList(),
          options: options.map((model) => model.toDragDropOptionEntity()).toList(),
        ),
        FormDragDropType.stressPlacement => QuestionPayloadEntity.stressPlacement(
          targetArea: targetArea,
          answers: answer.map((model) => model.toDragDropAnswerEntity()).toList(),
          options: options.map((model) => model.toDragDropOptionEntity()).toList(),
        ),
        FormDragDropType.arrangeTheSequence => QuestionPayloadEntity.arrangeTheSequence(
          answers: answer.map((model) => model.toDragDropAnswerEntity()).toList(),
          options: options.map((model) => model.toDragDropOptionEntity()).toList(),
        ),
      },
      QuestionType.record => QuestionPayloadEntity.speaking(
        record: record,
        maxDuration: maxDuration,
        maxCharacter: maxCharacter,
        scoringCriteria: mappedScoringCriteria,
      ),
      QuestionType.unknown => QuestionPayloadEntity.unsupported(rawType: type.rawValue),
    };
  }
}
