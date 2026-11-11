part of '../../onboarding.dart';

/// Content for the Name screen (screen 3 of 9).
@freezed
abstract class OnboardingNameConfigEntity with _$OnboardingNameConfigEntity {
  const factory OnboardingNameConfigEntity({
    @Default(BaseMultiLanguage()) BaseMultiLanguage heading,
    @Default(BaseMultiLanguage()) BaseMultiLanguage headingHighlight,
    @Default(BaseMultiLanguage()) BaseMultiLanguage helper,
    @Default(BaseMultiLanguage()) BaseMultiLanguage inputHint,
    @Default(BaseMultiLanguage()) BaseMultiLanguage ctaLabel,
    @Default('') String iconUrl,
  }) = _OnboardingNameConfigEntity;
}
