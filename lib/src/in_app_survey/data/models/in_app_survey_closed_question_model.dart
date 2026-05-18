part of '../../in_app_survey.dart';

enum InAppSurveyClosedQuestionType {
  @JsonValue('single_choice')
  singleChoice,
  @JsonValue('multiple_choice')
  multipleChoice,
}

@freezed
abstract class InAppSurveyClosedQuestionModel with _$InAppSurveyClosedQuestionModel {
  const factory InAppSurveyClosedQuestionModel({
    @Default(BaseMultiLanguage()) BaseMultiLanguage question,
    BaseMultiLanguage? guide,
    @Default(InAppSurveyClosedQuestionType.singleChoice) InAppSurveyClosedQuestionType type,
    @Default([]) List<InAppSurveyOptionModel> options,
  }) = _InAppSurveyClosedQuestionModel;

  factory InAppSurveyClosedQuestionModel.fromJson(Map<String, dynamic> json) => _$InAppSurveyClosedQuestionModelFromJson(json);
}

extension InAppSurveyClosedQuestionModelExtension on InAppSurveyClosedQuestionModel {
  InAppSurveyClosedQuestionEntity toEntity() => InAppSurveyClosedQuestionEntity(
        question: question,
        guide: guide,
        type: type,
        options: options.map((o) => o.toEntity()).toList(),
      );
}
