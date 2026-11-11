part of '../../../lesson.dart';

@freezed
abstract class QuestionNoCorrectChoiceOptionEntity with _$QuestionNoCorrectChoiceOptionEntity {
  const factory QuestionNoCorrectChoiceOptionEntity({
    @Default(BaseMultiLanguage()) BaseMultiLanguage value,
    @Default('') String documentGroupId,
  }) = _QuestionNoCorrectChoiceOptionEntity;

  factory QuestionNoCorrectChoiceOptionEntity.fromJson(Map<String, dynamic> json) => _$QuestionNoCorrectChoiceOptionEntityFromJson(json);
}
