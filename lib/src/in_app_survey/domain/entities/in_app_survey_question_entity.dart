part of '../../in_app_survey.dart';

@freezed
abstract class InAppSurveyQuestionEntity with _$InAppSurveyQuestionEntity {
  const factory InAppSurveyQuestionEntity({
    @Default(BaseMultiLanguage()) BaseMultiLanguage question,
    BaseMultiLanguage? guide,
  }) = _InAppSurveyQuestionEntity;

  factory InAppSurveyQuestionEntity.fromJson(Map<String, dynamic> json) => _$InAppSurveyQuestionEntityFromJson(json);
}
