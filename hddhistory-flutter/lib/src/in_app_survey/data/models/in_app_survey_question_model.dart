part of '../../in_app_survey.dart';

@freezed
abstract class InAppSurveyQuestionModel with _$InAppSurveyQuestionModel {
  const factory InAppSurveyQuestionModel({
    @Default(BaseMultiLanguage()) BaseMultiLanguage question,
    BaseMultiLanguage? guide,
  }) = _InAppSurveyQuestionModel;

  factory InAppSurveyQuestionModel.fromJson(Map<String, dynamic> json) => _$InAppSurveyQuestionModelFromJson(json);
}

extension InAppSurveyQuestionModelExtension on InAppSurveyQuestionModel {
  InAppSurveyQuestionEntity toEntity() => InAppSurveyQuestionEntity(
        question: question,
        guide: guide,
      );
}
