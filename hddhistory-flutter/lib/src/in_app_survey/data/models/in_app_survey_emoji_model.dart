part of '../../in_app_survey.dart';

@freezed
abstract class InAppSurveyEmojiModel with _$InAppSurveyEmojiModel {
  const factory InAppSurveyEmojiModel({
    String? name,
    @Default('') String lightUrl,
    @Default('') String darkUrl,
  }) = _InAppSurveyEmojiModel;

  factory InAppSurveyEmojiModel.fromJson(Map<String, dynamic> json) => _$InAppSurveyEmojiModelFromJson(json);
}

extension InAppSurveyEmojiModelExtension on InAppSurveyEmojiModel {
  InAppSurveyEmojiEntity toEntity() => InAppSurveyEmojiEntity(
        name: name,
        lightUrl: lightUrl,
        darkUrl: darkUrl,
      );
}
