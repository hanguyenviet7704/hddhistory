part of '../../in_app_survey.dart';

@freezed
abstract class InAppSurveyEmojiEntity with _$InAppSurveyEmojiEntity {
  const factory InAppSurveyEmojiEntity({
    String? name,
    @Default('') String lightIcon,
    @Default('') String darkIcon,
  }) = _InAppSurveyEmojiEntity;

  factory InAppSurveyEmojiEntity.fromJson(Map<String, dynamic> json) => _$InAppSurveyEmojiEntityFromJson(json);
}
