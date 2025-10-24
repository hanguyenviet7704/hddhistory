part of '../../exercise.dart';

@freezed
abstract class QuestionModel with _$QuestionModel {
  const factory QuestionModel({
    @Default(QuestionType.singleChoice) QuestionType type,
    @Default(FormDragDropType.textGapFilling) FormDragDropType form,
    @Default(0) int id,
    @Default('') String speechBubble,
    @Default('') String tag,
    @Default([]) List<ExerciseDocumentModel> document,
    @Default('') String explanation,
    @Default('') String targetArea,
    @Default([]) List<AnswerModel> answer,
    @Default([]) List<OptionModel> options,
    @Default([]) List<KeypointLevelType> level,
    @Default('') String record,
    @Default(0) int maxDuration,
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
    type: type,
    id: id,
    speechBubble: speechBubble,
    tag: tag,
    document: document.map((model) => model.toEntity()).toList(),
    explanation: explanation,
    targetArea: targetArea,
    answer: answer.map((model) => model.toEntity()).toList(),
    options: options.map((model) => model.toEntity()).toList(),
    level: level,
    form: form,
    record: record,
    maxDuration: maxDuration,
  );
}
