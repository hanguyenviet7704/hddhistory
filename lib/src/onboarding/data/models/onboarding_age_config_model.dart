part of '../../onboarding.dart';

@freezed
abstract class OnboardingAgeConfigModel with _$OnboardingAgeConfigModel {
  const factory OnboardingAgeConfigModel({
    @Default(BaseMultiLanguage()) BaseMultiLanguage headingTemplate,
    @Default(BaseMultiLanguage()) BaseMultiLanguage headingHighlight,
    @Default(BaseMultiLanguage()) BaseMultiLanguage ctaLabel,
    @Default([]) List<OnboardingAgeOptionModel> options,
    @Default('') String iconUrl,
  }) = _OnboardingAgeConfigModel;

  factory OnboardingAgeConfigModel.fromJson(Map<String, dynamic> json) => _$OnboardingAgeConfigModelFromJson(json);
}

extension OnboardingAgeConfigModelExtension on OnboardingAgeConfigModel {
  OnboardingAgeConfigEntity toEntity() => OnboardingAgeConfigEntity(
    headingTemplate: headingTemplate,
    headingHighlight: headingHighlight,
    ctaLabel: ctaLabel,
    options: options.map((option) => option.toEntity()).toList(),
    iconUrl: iconUrl,
  );
}

@freezed
abstract class OnboardingAgeOptionModel with _$OnboardingAgeOptionModel {
  const factory OnboardingAgeOptionModel({
    @Default('') String key,
    @Default(BaseMultiLanguage()) BaseMultiLanguage label,
    @Default(0) int order,
  }) = _OnboardingAgeOptionModel;

  factory OnboardingAgeOptionModel.fromJson(Map<String, dynamic> json) => _$OnboardingAgeOptionModelFromJson(json);
}

extension OnboardingAgeOptionModelExtension on OnboardingAgeOptionModel {
  // NOTE: `order` must be qualified with `this.` here — `package:injectable`
  // exports a top-level `const order = Order(0);` that otherwise shadows the
  // instance getter inside this extension body (see onboard_path_model.dart
  // for the same gotcha).
  OnboardingAgeOptionEntity toEntity() => OnboardingAgeOptionEntity(
    key: key,
    label: label,
    order: this.order,
  );
}
