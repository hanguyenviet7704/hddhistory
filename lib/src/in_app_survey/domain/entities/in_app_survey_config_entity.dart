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
}