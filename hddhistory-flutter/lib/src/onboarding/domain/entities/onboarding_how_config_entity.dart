part of '../../onboarding.dart';

/// Content for the onboarding v3 "How it works" screen.
@freezed
abstract class OnboardingHowConfigEntity with _$OnboardingHowConfigEntity {
  const factory OnboardingHowConfigEntity({
    @Default(BaseMultiLanguage()) BaseMultiLanguage eyebrow,
    @Default(BaseMultiLanguage()) BaseMultiLanguage heading,
    @Default(BaseMultiLanguage()) BaseMultiLanguage headingHighlight,
    @Default([]) List<OnboardingHowStepEntity> steps,
    @Default(BaseMultiLanguage()) BaseMultiLanguage footer,
    @Default(BaseMultiLanguage()) BaseMultiLanguage ctaLabel,
  }) = _OnboardingHowConfigEntity;
}

@freezed
abstract class OnboardingHowStepEntity with _$OnboardingHowStepEntity {
  const factory OnboardingHowStepEntity({
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @Default(BaseMultiLanguage()) BaseMultiLanguage body,
  }) = _OnboardingHowStepEntity;
}
