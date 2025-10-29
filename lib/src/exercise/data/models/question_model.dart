part of '../../exercise.dart';

@freezed
abstract class QuestionModel with _$QuestionModel {
  const factory QuestionModel({
    @Default(QuestionType.singleChoice) QuestionType type,
    @Default(FormDragDropType.textGapFilling) FormDragDropType form,
    @Default(0) int id,
    @Default('') String speechBubble,
    @Default(TagModel()) TagModel tag,
    @Default([]) List<ContentDocumentModel> document,
    @Default('') String explanation,
    @Default('') String targetArea,
    @Default([]) List<AnswerModel> answer,
    @Default([]) List<OptionModel> options,
    @Default([]) List<KeypointLevelType> level,
    @Default('') String record,
    @Default(0) int maxDuration,
    @Default(0) int maxCharacter,
    @DefaultInt() @Default(0) int mainQuestion,
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
  @JsonValue('drag_drop')
  dragAndDrop,
  @JsonValue('record')
  record,
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
  QuestionEntity toEntity() => QuestionEntity(
    type: toQuestionTypeEnum,
    id: id,
    speechBubble: speechBubble,
    tag: tag.toEntity(),
    document: document.map((model) => model.toEntity()).toList(),
    explanation: explanation,
    targetArea: targetArea,
    answer: answer.map((model) => model.toEntity()).toList(),
    options: options.map((model) => model.toEntity()).toList(),
    level: level,
    form: form,
    record: record,
    maxDuration: maxDuration,
    maxCharacter: maxCharacter,
    mainQuestion: mainQuestion,
  );

  QuestionTypeEnum get toQuestionTypeEnum {
    switch (type) {
      case QuestionType.singleChoice:
        return QuestionTypeEnum.singleChoice;
      case QuestionType.multipleChoice:
        return QuestionTypeEnum.multipleChoice;
      case QuestionType.record:
        return QuestionTypeEnum.speaking;
      case QuestionType.dragAndDrop:
        return switch (form) {
          FormDragDropType.textGapFilling => QuestionTypeEnum.dragAndDrop,
          FormDragDropType.cuesPlacement => QuestionTypeEnum.cuesPlacement,
          FormDragDropType.stressPlacement => QuestionTypeEnum.stressPlacement,
          FormDragDropType.arrangeTheSequence => QuestionTypeEnum.arrangeTheSequence,
        };
    }
  }
}
