part of '../../in_app_survey.dart';

@freezed
abstract class InAppSurveyResponseEntity with _$InAppSurveyResponseEntity {
  const factory InAppSurveyResponseEntity({
    @Default('') String configKey,
    @Default('') String branchId,
    @Default([]) List<String> closedAnswerIds,
    @Default('') String openAnswer,
  }) = _InAppSurveyResponseEntity;

  factory InAppSurveyResponseEntity.fromJson(Map<String, dynamic> json) => _$InAppSurveyResponseEntityFromJson(json);
}
