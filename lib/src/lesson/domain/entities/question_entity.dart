part of '../../lesson.dart';

@freezed
abstract class QuestionEntity with _$QuestionEntity {
  const factory QuestionEntity({
    @Default(QuestionTypeEnum.singleChoice) QuestionTypeEnum type,
    @Default(FormDragDropType.textGapFilling) FormDragDropType form,
    @Default(0) int id,
    @Default(BaseMultiLanguage()) BaseMultiLanguage speechBubble,
    @Default(TagEntity()) TagEntity tag,
    @Default([]) List<ContentDocumentEntity> document,
    @Default(BaseMultiLanguage()) BaseMultiLanguage explanation,
    @Default(BaseMultiLanguage()) BaseMultiLanguage targetArea,
    @Default([]) List<AnswerEntity> answer,
    @Default([]) List<OptionEntity> options,
    @Default([]) List<KeypointLevelType> level,
    @Default('') String record,
    @Default(0) int maxDuration,
    @Default(0) int maxCharacter,
    @Default(0) int maxScore,
    @Default(0) int completionTime,
    @Default([]) List<ScoringCriteriaEntity> scoringCriteria,
    @Default(0) int mainQuestion,
    @Default(KeypointEntity()) KeypointEntity keypoint,

    @Default(QuestionResultEntity()) QuestionResultEntity result,
  }) = _QuestionEntity;

  factory QuestionEntity.fromJson(Map<String, dynamic> json) => _$QuestionEntityFromJson(json);
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

@freezed
abstract class QuestionResultEntity with _$QuestionResultEntity {
  const factory QuestionResultEntity({
    @Default(0) int id,
    @Default(0) int questionId,
    @Default(0) int answerId,
    @Default(0) int score,
  }) = _QuestionResultEntity;

  factory QuestionResultEntity.fromJson(Map<String, dynamic> json) => _$QuestionResultEntityFromJson(json);
}

extension QuestionEntityExtension on QuestionEntity {
  bool get isCompleted => result.score > 0 && result.answerId > 0;

  String get questionText {
    if (document.isEmpty) return 'No question text';
    return document.first.data.content.text;
  }
}