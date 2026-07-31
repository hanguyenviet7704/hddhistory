part of '../../onboarding.dart';

/// Content for the Welcome screen (screen 2 of 9) — gradient headline, the
/// rotating deck of path cards, subtitle and primary CTA.
@freezed
abstract class OnboardingWelcomeConfigEntity with _$OnboardingWelcomeConfigEntity {
  const factory OnboardingWelcomeConfigEntity({
    @Default(BaseMultiLanguage()) BaseMultiLanguage titlePrefix,
    @Default('') String titleBrand,
    @Default(BaseMultiLanguage()) BaseMultiLanguage subtitle,
    @Default(BaseMultiLanguage()) BaseMultiLanguage ctaLabel,
    @Default([]) List<OnboardingWelcomeDeckItemEntity> deck,
  }) = _OnboardingWelcomeConfigEntity;
}

@freezed
abstract class OnboardingWelcomeDeckItemEntity with _$OnboardingWelcomeDeckItemEntity {
  const factory OnboardingWelcomeDeckItemEntity({
    @Default('') String key,
    @Default(BaseMultiLanguage()) BaseMultiLanguage label,
    @Default('') String imageUrl,
    @Default(0) int order,
  }) = _OnboardingWelcomeDeckItemEntity;
}
