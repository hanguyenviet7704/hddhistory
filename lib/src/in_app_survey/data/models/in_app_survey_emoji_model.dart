part of '../../in_app_survey.dart';

@freezed
abstract class InAppSurveyEmojiModel with _$InAppSurveyEmojiModel {
  const factory InAppSurveyEmojiModel({
    String? name,
    @Default('') String lightIcon,
    @Default('') String darkIcon,
  }) = _InAppSurveyEmojiModel;

  factory InAppSurveyEmojiModel.fromJson(Map<String, dynamic> json) => _$InAppSurveyEmojiModelFromJson(json);
}

extension InAppSurveyEmojiModelExtension on InAppSurveyEmojiModel {
  InAppSurveyEmojiEntity toEntity() => InAppSurveyEmojiEntity(
        name: name,
        lightIcon: lightIcon,
        darkIcon: darkIcon,
      );
}
