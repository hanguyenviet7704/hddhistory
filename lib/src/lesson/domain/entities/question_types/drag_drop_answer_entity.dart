part of '../../../lesson.dart';

@freezed
abstract class QuestionDragDropAnswerEntity with _$QuestionDragDropAnswerEntity {
  const factory QuestionDragDropAnswerEntity({
    @Default(0) int id,
    @Default(BaseMultiLanguage()) BaseMultiLanguage correctAnswer,
  }) = _QuestionDragDropAnswerEntity;

  factory QuestionDragDropAnswerEntity.fromJson(Map<String, dynamic> json) => _$QuestionDragDropAnswerEntityFromJson(json);
}
