part of '../../lesson.dart';

@freezed
abstract class QuestionModel with _$QuestionModel {
  const factory QuestionModel({
    @JsonKey(unknownEnumValue: QuestionType.unknown) @Default(QuestionType.singleChoice) QuestionType type,
    @JsonKey(unknownEnumValue: FormDragDropType.unknown) @Default(FormDragDropType.textGapFilling) FormDragDropType form,
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
    @JsonKey(fromJson: _keypointLevelTypeListFromJson, toJson: _keypointLevelTypeListToJson) @Default([]) List<KeypointLevelType> level,
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
  @JsonValue('unknown')
  unknown
  ;

  static KeypointLevelType fromRawValue(String value) {
    return switch (value) {
      'optional_practice' => KeypointLevelType.optionalPractice,
      'more_practice' => KeypointLevelType.morePractice,
      'weak_point' => KeypointLevelType.weakPoint,
      _ => KeypointLevelType.unknown,
    };
  }

  String get rawValue {
    return switch (this) {
      KeypointLevelType.optionalPractice => 'optional_practice',
      KeypointLevelType.morePractice => 'more_practice',
      KeypointLevelType.weakPoint => 'weak_point',
      KeypointLevelType.unknown => 'unknown',
    };
  }
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
  unknown
  ;

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
        FormDragDropType.unknown => QuestionTypeEnum.dragAndDrop,
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
  @JsonValue('unknown')
  unknown
  ;

  static FormDragDropType fromRawValue(String value) {
    return switch (value) {
      'Text Gap Filling' => FormDragDropType.textGapFilling,
      'Cues Placement' => FormDragDropType.cuesPlacement,
      'Stress Placement' => FormDragDropType.stressPlacement,
      'Arrange the Sequence' => FormDragDropType.arrangeTheSequence,
      _ => FormDragDropType.unknown,
    };
  }

  String get rawValue {
    return switch (this) {
      FormDragDropType.textGapFilling => 'Text Gap Filling',
      FormDragDropType.cuesPlacement => 'Cues Placement',
      FormDragDropType.stressPlacement => 'Stress Placement',
      FormDragDropType.arrangeTheSequence => 'Arrange the Sequence',
      FormDragDropType.unknown => 'unknown',
    };
  }
}

extension QuestionModelExtension on QuestionModel {
  QuestionEntity toEntity() {
    final mappedScoringCriteria = scoringCriteria.map((model) => model.toEntity()).toList();

    return QuestionEntity(
      type: type.toQuestionTypeEnum(form),
      id: id,
      exerciseId: exerciseId,
      speechBubble: speechBubble,
      tag: tag.toEntity(),
      document: document.map((model) => model.toEntity()).toList(),
      explanation: explanation,
      level: level,
      form: form,
      maxDuration: maxDuration,
      maxCharacter: maxCharacter,
      maxScore: maxScore,
      completionTime: completionTime,
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
        FormDragDropType.unknown => QuestionPayloadEntity.unsupported(rawType: '${type.rawValue}:${form.rawValue}'),
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

List<KeypointLevelType> _keypointLevelTypeListFromJson(Object? rawValue) {
  if (rawValue is! List) return const [];

  return rawValue.map((item) {
    if (item is KeypointLevelType) return item;
    if (item is String) return KeypointLevelType.fromRawValue(item);
    return KeypointLevelType.unknown;
  }).toList();
}

List<String> _keypointLevelTypeListToJson(List<KeypointLevelType> levels) {
  return levels.map((item) => item.rawValue).toList();
}
