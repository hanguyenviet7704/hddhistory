part of '../../progress.dart';

@freezed
abstract class ExerciseResultModel with _$ExerciseResultModel {
  const factory ExerciseResultModel({
    @Default('') String exerciseId,
    @Default(0.0) double score,
    @Default(false) bool passed,
    @Default(0) int numberOfCorrect,
    @Default(0) int numberOfIncorrect,
    @Default('') String reviews,
    @JsonKey(unknownEnumValue: QuestionType.unknown) @Default(QuestionType.singleChoice) QuestionType type,
    @JsonKey(unknownEnumValue: FormDragDropType.unknown) @Default(FormDragDropType.textGapFilling) FormDragDropType form,
    @Default([]) List<OptionModel> multipleAnswer,
    @Default(OptionModel()) OptionModel singleAnswer,
    @Default([]) List<OptionModel> dragDropAnswer,
    @Default(AnswerModel()) AnswerModel recordAnswer,
    DateTime? submittedAt,
  }) = _ExerciseResultModel;

  factory ExerciseResultModel.fromJson(Map<String, dynamic> json) => _$ExerciseResultModelFromJson(json);
}

extension ExerciseResultModelExtension on ExerciseResultModel {
  ExerciseResultEntity toEntity() => ExerciseResultEntity(
    exerciseId: exerciseId,
    score: score,
    passed: passed,
    numberOfCorrect: numberOfCorrect,
    numberOfIncorrect: numberOfIncorrect,
    reviews: reviews,
    type: type.toQuestionTypeEnum(form),
    form: form,
    multipleAnswer: multipleAnswer.map((model) => model.toEntity()).toList(),
    singleAnswer: singleAnswer.toEntity(),
    dragDropAnswer: dragDropAnswer.map((model) => model.toEntity()).toList(),
    recordAnswer: recordAnswer.toEntity(),
    submittedAt: submittedAt,
  );
}
