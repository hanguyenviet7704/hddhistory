part of '../../onboarding.dart';

/// Content for the onboarding v3 "Desire" screen.
@freezed
abstract class OnboardingDesireConfigEntity with _$OnboardingDesireConfigEntity {
  const factory OnboardingDesireConfigEntity({
    @Default(BaseMultiLanguage()) BaseMultiLanguage heading,
    @Default(BaseMultiLanguage()) BaseMultiLanguage headingHighlight,
    @Default(BaseMultiLanguage()) BaseMultiLanguage helper,
  }) = _OnboardingDesireConfigEntity;
}
