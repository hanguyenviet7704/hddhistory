part of '../../lesson.dart';

@freezed
abstract class QuestionEntity with _$QuestionEntity {
  const factory QuestionEntity({
    @Default(QuestionTypeEnum.singleChoice) QuestionTypeEnum type,
    @Default(FormDragDropType.textGapFilling) FormDragDropType form,
    @Default(0) int id,
    @Default('') String speechBubble,
    @Default(TagEntity()) TagEntity tag,
    @Default([]) List<ContentDocumentEntity> document,
    @Default('') String explanation,
    @Default('') String targetArea,
    @Default([]) List<AnswerEntity> answer,
    @Default([]) List<OptionEntity> options,
    @Default([]) List<KeypointLevelType> level,
    @Default('') String record,
    @Default(0) int maxDuration,
    @Default(0) int maxCharacter,
    @Default(0) int maxScore,
    @Default(0) int completionTime,
    @Default(0) int mainQuestion,
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
