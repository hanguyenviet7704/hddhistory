part of '../../exercise.dart';

@freezed
abstract class QuestionModel with _$QuestionModel {
  const factory QuestionModel({
    @Default('') String type,
    @Default(0) int id,
    @Default('') String speechBubble,
    @Default('') String tag,
    @Default([]) List<ExerciseDocumentModel> document,
    @Default('') String explanation,
    @Default('') String targetArea,
    @Default([]) List<AnswerModel> answer,
    @Default([]) List<OptionModel> options,
    @Default([]) List<String> level,
    @Default('') String form,
    @Default('') String record,
    @Default(0) int maxDuration,
  }) = _QuestionModel;

  factory QuestionModel.fromJson(Map<String, dynamic> json) => _$QuestionModelFromJson(json);
}

extension QuestionModelExtension on QuestionModel {
  QuestionEntity toEntity() => QuestionEntity(
    id: id,
    speechBubble: speechBubble,
    tag: tag,
    document: document,
    explanation: explanation,
    targetArea: targetArea,
    answer: answer,
    options: options,
    level: level,
    form: form,
    record: record,
    maxDuration: maxDuration,
  );
}