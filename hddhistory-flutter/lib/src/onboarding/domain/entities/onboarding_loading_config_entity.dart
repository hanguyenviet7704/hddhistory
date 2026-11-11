part of '../../onboarding.dart';

/// Content for the onboarding v3 "Loading/generating plan" screen.
@freezed
abstract class OnboardingLoadingConfigEntity with _$OnboardingLoadingConfigEntity {
  const factory OnboardingLoadingConfigEntity({
    @Default(BaseMultiLanguage()) BaseMultiLanguage heading,
    @Default(BaseMultiLanguage()) BaseMultiLanguage headingHighlight,
    @Default([]) List<BaseMultiLanguage> lines,
  }) = _OnboardingLoadingConfigEntity;
}
