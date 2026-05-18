part of '../../in_app_survey.dart';

@freezed
abstract class InAppSurveyConfigModel with _$InAppSurveyConfigModel {
  const factory InAppSurveyConfigModel({
    @Default('') String configKey,
    @Default(InAppSurveyQuestionModel()) InAppSurveyQuestionModel introQuestion,
    @Default([]) List<InAppSurveyBranchModel> branches,
  }) = _InAppSurveyConfigModel;

  factory InAppSurveyConfigModel.fromJson(Map<String, dynamic> json) => _$InAppSurveyConfigModelFromJson(json);
}

extension InAppSurveyConfigModelExtension on InAppSurveyConfigModel {
  InAppSurveyConfigEntity toEntity() => InAppSurveyConfigEntity(
        configKey: configKey,
        introQuestion: introQuestion.toEntity(),
        branches: branches.map((b) => b.toEntity()).toList(),
      );
}

