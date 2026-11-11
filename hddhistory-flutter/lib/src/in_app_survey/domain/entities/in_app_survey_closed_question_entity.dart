part of '../../in_app_survey.dart';

@freezed
abstract class InAppSurveyClosedQuestionEntity with _$InAppSurveyClosedQuestionEntity {
  const factory InAppSurveyClosedQuestionEntity({
    @Default(BaseMultiLanguage()) BaseMultiLanguage question,
    BaseMultiLanguage? guide,
    @Default(InAppSurveyClosedQuestionType.singleChoice) InAppSurveyClosedQuestionType type,
    @Default([]) List<InAppSurveyOptionEntity> options,
  }) = _InAppSurveyClosedQuestionEntity;

  factory InAppSurveyClosedQuestionEntity.fromJson(Map<String, dynamic> json) => _$InAppSurveyClosedQuestionEntityFromJson(json);
}
