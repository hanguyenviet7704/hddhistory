part of '../../in_app_survey.dart';

@freezed
abstract class InAppSurveyBranchModel with _$InAppSurveyBranchModel {
  const factory InAppSurveyBranchModel({
    @Default('') String id,
    @Default(InAppSurveyEmojiModel()) InAppSurveyEmojiModel emoji,
    @Default(InAppSurveyClosedQuestionModel()) InAppSurveyClosedQuestionModel closedQuestion,
    @Default(InAppSurveyQuestionModel()) InAppSurveyQuestionModel openQuestion,
    @Default(0) int index,
  }) = _InAppSurveyBranchModel;

  factory InAppSurveyBranchModel.fromJson(Map<String, dynamic> json) => _$InAppSurveyBranchModelFromJson(json);
}

extension InAppSurveyBranchModelExtension on InAppSurveyBranchModel {
  InAppSurveyBranchEntity toEntity() => InAppSurveyBranchEntity(
        id: id,
        emoji: emoji.toEntity(),
        closedQuestion: closedQuestion.toEntity(),
        openQuestion: openQuestion.toEntity(),
        index: index,
      );
}
