part of '../../lesson.dart';

@freezed
abstract class QuestionEntity with _$QuestionEntity {
  const factory QuestionEntity({
    @Default(QuestionTypeEnum.singleChoice) QuestionTypeEnum type,
    @Default(FormDragDropType.textGapFilling) FormDragDropType form,
    @Default(0) int id,
    @Default('') String exerciseId,
    @Default(BaseMultiLanguage()) BaseMultiLanguage speechBubble,
    @Default(TagEntity()) TagEntity tag,
    @Default([]) List<ContentDocumentEntity> document,
    @Default(BaseMultiLanguage()) BaseMultiLanguage explanation,
    @Default([]) List<KeypointLevelType> level,
    @Default(0) int maxDuration,
    @Default(0) int maxCharacter,
    @Default(0) int maxScore,
    @Default(0) int completionTime,
    @Default(0) int mainQuestion,
    @Default(KeypointEntity()) KeypointEntity keypoint,
    @Default(QuestionPayloadEntity.singleChoice()) QuestionPayloadEntity typedPayload,

    @Default(ExerciseResultEntity()) ExerciseResultEntity result,
  }) = _QuestionEntity;

  factory QuestionEntity.fromJson(Map<String, dynamic> json) => _resolveQuestionEntityAfterJson(
    _$QuestionEntityFromJson(json),
    json,
  );
}

enum QuestionTypeEnum {
  @JsonValue('single_choice')
  singleChoice,
  @JsonValue('multiple_choice')
  multipleChoice,
  @JsonValue('drag_and_drop')
  dragAndDrop,
  @JsonValue('arrange_the_sequence')
  arrangeTheSequence,
  @JsonValue('cues_placement')
  cuesPlacement,
  @JsonValue('stress_placement')
  stressPlacement,
  @JsonValue('speaking')
  speaking,
}

extension QuestionEntityExtension on QuestionEntity {
  String get explanationText => explanation.text;

  bool get hasResult {
    if (result.multipleAnswer.isNotEmpty || result.dragDropAnswer.isNotEmpty) return true;
    if (result.singleAnswer.id != 0 || result.singleAnswer.labelText.isNotEmpty) return true;
    if (result.recordAnswer.record.isNotEmpty || result.recordAnswer.review.isNotEmpty) return true;
    return result.exerciseId.isNotEmpty;
  }

  bool get isCompleted => false;

  String get questionText {
    if (document.isEmpty) return 'No question text';
    return document.first.data.content.text;
  }

  String get keypointId {
    if (keypoint.id.isNotEmpty) return keypoint.id;
    LearningItemEntity currentLearningItem = AppDI.injector.get<LessonCubit>().state.currentLearningItem;
    if (currentLearningItem.keypointId.isNotEmpty) return currentLearningItem.keypointId;
    return '';
  }

  bool get hasExplanation => explanationText.isNotEmpty;
}

QuestionPayloadEntity _resolveTypedPayloadFromJson({
  required Map<String, dynamic> json,
  required QuestionPayloadEntity currentPayload,
  required QuestionTypeEnum fallbackType,
  required FormDragDropType fallbackForm,
  required int fallbackMaxDuration,
  required int fallbackMaxCharacter,
}) {
  final rawTypedPayload = json['typedPayload'];
  if (rawTypedPayload is Map && rawTypedPayload.isNotEmpty) {
    return currentPayload;
  }

  return _inferTypedPayloadFromLegacyJson(
    json: json,
    type: fallbackType,
    form: fallbackForm,
    maxDuration: fallbackMaxDuration,
    maxCharacter: fallbackMaxCharacter,
  );
}

QuestionEntity _resolveQuestionEntityAfterJson(
  QuestionEntity parsed,
  Map<String, dynamic> json,
) {
  final resolvedPayload = _resolveTypedPayloadFromJson(
    json: json,
    currentPayload: parsed.typedPayload,
    fallbackType: parsed.type,
    fallbackForm: parsed.form,
    fallbackMaxDuration: parsed.maxDuration,
    fallbackMaxCharacter: parsed.maxCharacter,
  );

  return parsed.copyWith(typedPayload: resolvedPayload);
}

QuestionPayloadEntity _inferTypedPayloadFromLegacyJson({
  required Map<String, dynamic> json,
  required QuestionTypeEnum type,
  required FormDragDropType form,
  required int maxDuration,
  required int maxCharacter,
}) {
  final optionModels = _legacyOptionModelsFromJson(json);
  final answerModels = _legacyAnswerModelsFromJson(json);
  final documentGroups = _legacyDocumentGroupsFromJson(json);
  final targetArea = _legacyTargetAreaFromJson(json);
  final record = _legacyRecordFromJson(json);
  final scoringCriteria = _legacyScoringCriteriaFromJson(json);

  return switch (type) {
    QuestionTypeEnum.singleChoice => _inferSingleChoicePayload(
      optionModels: optionModels,
      documentGroups: documentGroups,
    ),
    QuestionTypeEnum.multipleChoice => QuestionPayloadEntity.multipleChoice(
      options: optionModels.map(_legacyChoiceOptionFromModel).toList(),
    ),
    QuestionTypeEnum.dragAndDrop => switch (form) {
      FormDragDropType.textGapFilling => QuestionPayloadEntity.dragAndDrop(
        targetArea: targetArea,
        answers: answerModels.map((model) => model.toDragDropAnswerEntity()).toList(),
        options: optionModels.map(_legacyDragDropOptionFromModel).toList(),
      ),
      FormDragDropType.cuesPlacement => QuestionPayloadEntity.cuesPlacement(
        targetArea: targetArea,
        answers: answerModels.map((model) => model.toDragDropAnswerEntity()).toList(),
        options: optionModels.map(_legacyDragDropOptionFromModel).toList(),
      ),
      FormDragDropType.stressPlacement => QuestionPayloadEntity.stressPlacement(
        targetArea: targetArea,
        answers: answerModels.map((model) => model.toDragDropAnswerEntity()).toList(),
        options: optionModels.map(_legacyDragDropOptionFromModel).toList(),
      ),
      FormDragDropType.arrangeTheSequence => QuestionPayloadEntity.arrangeTheSequence(
        answers: answerModels.map((model) => model.toDragDropAnswerEntity()).toList(),
        options: optionModels.map(_legacyDragDropOptionFromModel).toList(),
      ),
    },
    QuestionTypeEnum.arrangeTheSequence => QuestionPayloadEntity.arrangeTheSequence(
      answers: answerModels.map((model) => model.toDragDropAnswerEntity()).toList(),
      options: optionModels.map(_legacyDragDropOptionFromModel).toList(),
    ),
    QuestionTypeEnum.cuesPlacement => QuestionPayloadEntity.cuesPlacement(
      targetArea: targetArea,
      answers: answerModels.map((model) => model.toDragDropAnswerEntity()).toList(),
      options: optionModels.map(_legacyDragDropOptionFromModel).toList(),
    ),
    QuestionTypeEnum.stressPlacement => QuestionPayloadEntity.stressPlacement(
      targetArea: targetArea,
      answers: answerModels.map((model) => model.toDragDropAnswerEntity()).toList(),
      options: optionModels.map(_legacyDragDropOptionFromModel).toList(),
    ),
    QuestionTypeEnum.speaking => QuestionPayloadEntity.speaking(
      record: record,
      maxDuration: maxDuration,
      maxCharacter: maxCharacter,
      scoringCriteria: scoringCriteria,
    ),
  };
}

QuestionPayloadEntity _inferSingleChoicePayload({
  required List<OptionModel> optionModels,
  required List<QuestionNoCorrectDocumentGroupEntity> documentGroups,
}) {
  final noCorrectOptions = optionModels.map(_legacyNoCorrectChoiceOptionFromModel).toList();
  final hasNoCorrectData = documentGroups.isNotEmpty || noCorrectOptions.any((option) => option.documentGroupId.isNotEmpty);
  if (hasNoCorrectData) {
    return QuestionPayloadEntity.singleChoiceNoCorrectAnswer(
      options: noCorrectOptions,
      documentGroups: documentGroups,
    );
  }

  return QuestionPayloadEntity.singleChoice(
    options: optionModels.map(_legacyChoiceOptionFromModel).toList(),
  );
}

List<OptionModel> _legacyOptionModelsFromJson(Map<String, dynamic> json) {
  final rawOptions = json['options'];
  if (rawOptions is! List) return const [];
  return rawOptions.whereType<Map>().map((item) => OptionModel.fromJson(Map<String, dynamic>.from(item))).toList();
}

List<AnswerModel> _legacyAnswerModelsFromJson(Map<String, dynamic> json) {
  final rawAnswers = json['answer'];
  if (rawAnswers is! List) return const [];
  return rawAnswers.whereType<Map>().map((item) => AnswerModel.fromJson(Map<String, dynamic>.from(item))).toList();
}

List<QuestionNoCorrectDocumentGroupEntity> _legacyDocumentGroupsFromJson(Map<String, dynamic> json) {
  final rawDocumentGroups = json['documentGroups'];
  if (rawDocumentGroups is! List) return const [];
  return rawDocumentGroups.whereType<Map>().map((item) => NoCorrectDocumentGroupModel.fromJson(Map<String, dynamic>.from(item)).toEntity()).toList();
}

BaseMultiLanguage _legacyTargetAreaFromJson(Map<String, dynamic> json) {
  final rawTargetArea = json['targetArea'];
  if (rawTargetArea is! Map) return const BaseMultiLanguage();
  return BaseMultiLanguage.fromJson(Map<String, dynamic>.from(rawTargetArea));
}

String _legacyRecordFromJson(Map<String, dynamic> json) {
  final rawRecord = json['record'];
  if (rawRecord is! String) return '';
  return rawRecord;
}

List<ScoringCriteriaEntity> _legacyScoringCriteriaFromJson(Map<String, dynamic> json) {
  final rawScoringCriteria = json['scoringCriteria'];
  if (rawScoringCriteria is! List) return const [];
  return rawScoringCriteria.whereType<Map>().map((item) => ScoringCriteriaModel.fromJson(Map<String, dynamic>.from(item)).toEntity()).toList();
}

QuestionChoiceOptionEntity _legacyChoiceOptionFromModel(OptionModel model) {
  return QuestionChoiceOptionEntity(
    value: _legacyPickOptionValue(model),
    isCorrect: model.isCorrect,
  );
}

QuestionNoCorrectChoiceOptionEntity _legacyNoCorrectChoiceOptionFromModel(OptionModel model) {
  return QuestionNoCorrectChoiceOptionEntity(
    value: _legacyPickOptionValue(model),
    documentGroupId: model.documentGroupId,
  );
}

QuestionDragDropOptionEntity _legacyDragDropOptionFromModel(OptionModel model) {
  return QuestionDragDropOptionEntity(
    id: model.id,
    text: _legacyPickOptionText(model),
  );
}

BaseMultiLanguage _legacyPickOptionValue(OptionModel model) {
  if (_hasAnyTranslation(model.value)) return model.value;
  return model.text;
}

BaseMultiLanguage _legacyPickOptionText(OptionModel model) {
  if (_hasAnyTranslation(model.text)) return model.text;
  return model.value;
}

bool _hasAnyTranslation(BaseMultiLanguage value) {
  return value.en.trim().isNotEmpty || value.vi.trim().isNotEmpty || value.zh.trim().isNotEmpty;
}
