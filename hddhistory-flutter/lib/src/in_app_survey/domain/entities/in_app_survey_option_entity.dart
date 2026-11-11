part of '../../in_app_survey.dart';

@freezed
abstract class InAppSurveyOptionEntity with _$InAppSurveyOptionEntity {
  const factory InAppSurveyOptionEntity({
    @Default('') String id,
    @Default('') String icon,
    @Default(BaseMultiLanguage()) BaseMultiLanguage value,
  }) = _InAppSurveyOptionEntity;

  factory InAppSurveyOptionEntity.fromJson(Map<String, dynamic> json) => _$InAppSurveyOptionEntityFromJson(json);
}
