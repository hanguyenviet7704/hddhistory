part of '../../onboarding.dart';

@freezed
abstract class OnboardingThemeConfigModel with _$OnboardingThemeConfigModel {
  const factory OnboardingThemeConfigModel({
    @Default(BaseMultiLanguage()) BaseMultiLanguage titlePrefix,
    @Default(BaseMultiLanguage()) BaseMultiLanguage titleHighlight,
    @Default(BaseMultiLanguage()) BaseMultiLanguage subtitle,
    @Default(BaseMultiLanguage()) BaseMultiLanguage ctaLabel,
    @Default(BaseMultiLanguage()) BaseMultiLanguage helper,
  }) = _OnboardingThemeConfigModel;

  factory OnboardingThemeConfigModel.fromJson(Map<String, dynamic> json) => _$OnboardingThemeConfigModelFromJson(json);
}

extension OnboardingThemeConfigModelExtension on OnboardingThemeConfigModel {
  OnboardingThemeConfigEntity toEntity() => OnboardingThemeConfigEntity(
    titlePrefix: titlePrefix,
    titleHighlight: titleHighlight,
    subtitle: subtitle,
    ctaLabel: ctaLabel,
    helper: helper,
  );
}
