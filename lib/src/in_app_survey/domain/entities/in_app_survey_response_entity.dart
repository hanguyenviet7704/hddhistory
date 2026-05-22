part of '../../in_app_survey.dart';

@freezed
abstract class InAppSurveyResponseEntity with _$InAppSurveyResponseEntity {
  const factory InAppSurveyResponseEntity({
    @Default('') String branchId,
    @Default([]) List<String> selectedOptionIds,
    @Default('') String feedback,
  }) = _InAppSurveyResponseEntity;

  factory InAppSurveyResponseEntity.fromJson(Map<String, dynamic> json) => _$InAppSurveyResponseEntityFromJson(json);
}
