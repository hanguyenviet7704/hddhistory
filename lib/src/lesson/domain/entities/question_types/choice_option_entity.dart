part of '../../../lesson.dart';

@freezed
abstract class QuestionChoiceOptionEntity with _$QuestionChoiceOptionEntity {
  const factory QuestionChoiceOptionEntity({
    @Default(BaseMultiLanguage()) BaseMultiLanguage value,
    @Default(false) bool isCorrect,
  }) = _QuestionChoiceOptionEntity;

  factory QuestionChoiceOptionEntity.fromJson(Map<String, dynamic> json) => _$QuestionChoiceOptionEntityFromJson(json);
}
