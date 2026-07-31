part of '../../onboarding.dart';

/// Content for the Age screen (screen 4 of 9) — `headingTemplate` contains a
/// literal `{name}` token substituted with the name captured on screen 3.
@freezed
abstract class OnboardingAgeConfigEntity with _$OnboardingAgeConfigEntity {
  const factory OnboardingAgeConfigEntity({
    @Default(BaseMultiLanguage()) BaseMultiLanguage headingTemplate,
    @Default(BaseMultiLanguage()) BaseMultiLanguage headingHighlight,
    @Default(BaseMultiLanguage()) BaseMultiLanguage ctaLabel,
    @Default([]) List<OnboardingAgeOptionEntity> options,
    @Default('') String iconUrl,
  }) = _OnboardingAgeConfigEntity;
}

@freezed
abstract class OnboardingAgeOptionEntity with _$OnboardingAgeOptionEntity {
  const factory OnboardingAgeOptionEntity({
    @Default('') String key,
    @Default(BaseMultiLanguage()) BaseMultiLanguage label,
    @Default(0) int order,
  }) = _OnboardingAgeOptionEntity;
}
