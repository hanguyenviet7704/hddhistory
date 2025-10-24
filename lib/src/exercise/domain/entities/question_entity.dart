part of '../../exercise.dart';

@freezed
abstract class QuestionEntity with _$QuestionEntity {
  const factory QuestionEntity({
    @Default('') String type,
    @Default(0) int id,
    @Default('') String speechBubble,
    @Default('') String tag,
    @Default([]) List<ExerciseDocumentEntity> document,
    @Default('') String explanation,
    @Default('') String targetArea,
    @Default([]) List<AnswerEntity> answer,
    @Default([]) List<OptionEntity> options,
    @Default([]) List<String> level,
    @Default('') String form,
    @Default('') String record,
    @Default(0) int maxDuration,
  }) = _QuestionEntity;

  factory QuestionEntity.fromJson(Map<String, dynamic> json) => _$QuestionEntityFromJson(json);
}

