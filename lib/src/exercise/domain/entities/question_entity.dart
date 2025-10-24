part of '../../exercise.dart';

@freezed
abstract class QuestionEntity with _$QuestionEntity {
  const factory QuestionEntity({
    @Default(QuestionType.singleChoice) QuestionType type,
    @Default(FormDragDropType.textGapFilling) FormDragDropType form,
    @Default(0) int id,
    @Default('') String speechBubble,
    @Default('') String tag,
    @Default([]) List<ExerciseDocumentEntity> document,
    @Default('') String explanation,
    @Default('') String targetArea,
    @Default([]) List<AnswerEntity> answer,
    @Default([]) List<OptionEntity> options,
    @Default([]) List<KeypointLevelType> level,
    @Default('') String record,
    @Default(0) int maxDuration,
  }) = _QuestionEntity;

  factory QuestionEntity.fromJson(Map<String, dynamic> json) => _$QuestionEntityFromJson(json);
}

