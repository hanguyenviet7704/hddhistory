part of '../../in_app_survey.dart';

@freezed
abstract class InAppSurveyEmojiEntity with _$InAppSurveyEmojiEntity {
  const factory InAppSurveyEmojiEntity({
    String? name,
    @Default('') String lightUrl,
    @Default('') String darkUrl,
  }) = _InAppSurveyEmojiEntity;

  factory InAppSurveyEmojiEntity.fromJson(Map<String, dynamic> json) => _$InAppSurveyEmojiEntityFromJson(json);
}
