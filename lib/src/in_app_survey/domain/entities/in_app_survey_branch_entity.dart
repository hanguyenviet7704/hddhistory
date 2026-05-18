part of '../../in_app_survey.dart';

@freezed
abstract class InAppSurveyBranchEntity with _$InAppSurveyBranchEntity {
  const factory InAppSurveyBranchEntity({
    @Default('') String id,
    @Default(InAppSurveyEmojiEntity()) InAppSurveyEmojiEntity emoji,
    @Default(InAppSurveyClosedQuestionEntity()) InAppSurveyClosedQuestionEntity closedQuestion,
    @Default(InAppSurveyQuestionEntity()) InAppSurveyQuestionEntity openQuestion,
    @Default(0) int index,
  }) = _InAppSurveyBranchEntity;

  factory InAppSurveyBranchEntity.fromJson(Map<String, dynamic> json) => _$InAppSurveyBranchEntityFromJson(json);
}
