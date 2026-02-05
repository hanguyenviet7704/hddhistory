part of '../../onboard.dart';

@freezed
abstract class OnboardOptionModel with _$OnboardOptionModel {
  const factory OnboardOptionModel({
    @Default(0) int id,
    @Default('') String icon,
    @Default(BaseMultiLanguage()) BaseMultiLanguage label,
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @Default('') String trackingLabel,
  }) = _OnboardOptionModel;

  factory OnboardOptionModel.fromJson(Map<String, dynamic> json) => _$OnboardOptionModelFromJson(json);
}

extension OnboardOptionModelExtension on OnboardOptionModel {
  OnboardOptionEntity toEntity() => OnboardOptionEntity(
    id: id,
    icon: icon,
    label: label,
    title: title,
    trackingLabel: trackingLabel,
  );
}
