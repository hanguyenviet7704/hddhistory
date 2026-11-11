part of '../../onboarding.dart';

/// Content for the terminal "Pick theme" screen (P9 of onboard_v2, "Make it
/// yours") — a full-screen study-theme picker that reuses the existing
/// [StudyThemeCubit] catalogue. The course list config (`pick`) calls its two
/// title fragments `heading`/`headingHighlight`; this section instead mirrors
/// the API contract's `titlePrefix`/`titleHighlight` naming (see
/// hddhistory-api/plans/260721-onboard-v2-config-driven/contract.md).
@freezed
abstract class OnboardingThemeConfigEntity with _$OnboardingThemeConfigEntity {
  const factory OnboardingThemeConfigEntity({
    @Default(BaseMultiLanguage()) BaseMultiLanguage titlePrefix,
    @Default(BaseMultiLanguage()) BaseMultiLanguage titleHighlight,
    @Default(BaseMultiLanguage()) BaseMultiLanguage subtitle,
    @Default(BaseMultiLanguage()) BaseMultiLanguage ctaLabel,
    @Default(BaseMultiLanguage()) BaseMultiLanguage helper,
  }) = _OnboardingThemeConfigEntity;
}
