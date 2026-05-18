part of '../../in_app_survey.dart';

@freezed
abstract class InAppSurveyConfigEntity with _$InAppSurveyConfigEntity {
  const factory InAppSurveyConfigEntity({
    @Default('') String configKey,
    @Default(InAppSurveyQuestionEntity()) InAppSurveyQuestionEntity introQuestion,
    @Default([]) List<InAppSurveyBranchEntity> branches,
  }) = _InAppSurveyConfigEntity;

  factory InAppSurveyConfigEntity.fromJson(Map<String, dynamic> json) => _$InAppSurveyConfigEntityFromJson(json);
}

extension InAppSurveyConfigEntityExtension on InAppSurveyConfigEntity {
  List<InAppSurveyEmojiEntity> get emojis => branches.map((b) => b.emoji).toList();

  bool get hasUsableConfig => branches.isNotEmpty && branches.every((branch) => branch.isUsableForSurvey);
}

extension InAppSurveyBranchEntityExtension on InAppSurveyBranchEntity {
  bool get hasUsableEmoji => emoji.lightUrl.trim().isNotEmpty || emoji.darkUrl.trim().isNotEmpty || (emoji.name?.trim().isNotEmpty ?? false);

  bool get hasUsableClosedQuestion => closedQuestion.options.any((option) => option.id.trim().isNotEmpty);

  bool get isUsableForSurvey => id.trim().isNotEmpty && hasUsableEmoji && hasUsableClosedQuestion;
}
