part of '../../progress.dart';

@freezed
abstract class ExerciseResultEntity with _$ExerciseResultEntity {
  const factory ExerciseResultEntity({
    @Default('') String exerciseId,
    @Default(0.0) double score,
    @Default(false) bool passed,
    @Default(0) int numberOfCorrect,
    @Default(0) int numberOfIncorrect,
    @Default('') String reviews,
    @Default(QuestionTypeEnum.singleChoice) QuestionTypeEnum type,
    @Default(FormDragDropType.textGapFilling) FormDragDropType form,
    @Default([]) List<OptionEntity> multipleAnswer,
    @Default(OptionEntity()) OptionEntity singleAnswer,
    @Default([]) List<OptionEntity> dragDropAnswer,
    @Default(AnswerEntity()) AnswerEntity recordAnswer,
    DateTime? submittedAt,
  }) = _ExerciseResultEntity;

  factory ExerciseResultEntity.fromJson(Map<String, dynamic> json) => _$ExerciseResultEntityFromJson(json);
}

extension ExerciseResultEntityExtension on ExerciseResultEntity {
  bool get isCorrect => false;
}
