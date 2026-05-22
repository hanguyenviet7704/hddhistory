part of '../../in_app_survey.dart';

@freezed
abstract class InAppSurveyOptionModel with _$InAppSurveyOptionModel {
  const factory InAppSurveyOptionModel({
    @Default('') String id,
    @Default('') String icon,
    @Default(BaseMultiLanguage()) BaseMultiLanguage value,
  }) = _InAppSurveyOptionModel;

  factory InAppSurveyOptionModel.fromJson(Map<String, dynamic> json) => _$InAppSurveyOptionModelFromJson(json);
}

extension InAppSurveyOptionModelExtension on InAppSurveyOptionModel {
  InAppSurveyOptionEntity toEntity() => InAppSurveyOptionEntity(
        id: id,
        icon: icon,
        value: value,
      );
}
