part of '../../lesson.dart';

@freezed
abstract class QuestionPayloadEntity with _$QuestionPayloadEntity {
  const factory QuestionPayloadEntity.singleChoice({
    @Default([]) List<QuestionChoiceOptionEntity> options,
  }) = QuestionSingleChoicePayloadEntity;

  const factory QuestionPayloadEntity.multipleChoice({
    @Default([]) List<QuestionChoiceOptionEntity> options,
  }) = QuestionMultipleChoicePayloadEntity;

  const factory QuestionPayloadEntity.singleChoiceNoCorrectAnswer({
    @Default([]) List<QuestionNoCorrectChoiceOptionEntity> options,
    @Default([]) List<QuestionNoCorrectDocumentGroupEntity> documentGroups,
  }) = QuestionSingleChoiceNoCorrectAnswerPayloadEntity;

  const factory QuestionPayloadEntity.dragAndDrop({
    @Default(BaseMultiLanguage()) BaseMultiLanguage targetArea,
    @Default([]) List<QuestionDragDropAnswerEntity> answers,
    @Default([]) List<QuestionDragDropOptionEntity> options,
  }) = QuestionDragAndDropPayloadEntity;

  const factory QuestionPayloadEntity.arrangeTheSequence({
    @Default([]) List<QuestionDragDropAnswerEntity> answers,
    @Default([]) List<QuestionDragDropOptionEntity> options,
  }) = QuestionArrangeTheSequencePayloadEntity;

  const factory QuestionPayloadEntity.cuesPlacement({
    @Default(BaseMultiLanguage()) BaseMultiLanguage targetArea,
    @Default([]) List<QuestionDragDropAnswerEntity> answers,
    @Default([]) List<QuestionDragDropOptionEntity> options,
  }) = QuestionCuesPlacementPayloadEntity;

  const factory QuestionPayloadEntity.stressPlacement({
    @Default(BaseMultiLanguage()) BaseMultiLanguage targetArea,
    @Default([]) List<QuestionDragDropAnswerEntity> answers,
    @Default([]) List<QuestionDragDropOptionEntity> options,
  }) = QuestionStressPlacementPayloadEntity;

  const factory QuestionPayloadEntity.speaking({
    @Default('') String record,
    @Default(0) int maxDuration,
    @Default(0) int maxCharacter,
    @Default([]) List<ScoringCriteriaEntity> scoringCriteria,
  }) = QuestionSpeakingPayloadEntity;

  const factory QuestionPayloadEntity.unsupported({
    @Default('') String rawType,
  }) = QuestionUnsupportedPayloadEntity;

  factory QuestionPayloadEntity.fromJson(Map<String, dynamic> json) => _$QuestionPayloadEntityFromJson(json);
}
