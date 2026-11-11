part of '../../onboarding.dart';

/// Root content-config entity for the new 9-screen onboarding flow, fetched
/// once from `GET /api/v1/onboarding-config`.
///
/// Named `OnboardingContentConfigEntity` (not `OnboardingConfigEntity`) to
/// avoid colliding with the pre-existing [OnboardingConfigEntity] in
/// `lib/src/common` — that one is an unrelated remote-config feature flag
/// (`enable` / `flowType`) read by splash, not this screen content.
///
/// Every field defaults to an empty [BaseMultiLanguage] / empty list. That is
/// intentional: consumers substitute hardcoded EN/VI defaults for any field
/// that comes back empty (see `onboard_v2`'s `OnboardV2ConfigMapper` +
/// `onbCopy`, the shipped consumer of this config), so a totally-empty entity
/// (first run before the backend is seeded, or the fetch failing offline)
/// renders identically to a fully-seeded one. See [OnboardingRepository].
@freezed
abstract class OnboardingContentConfigEntity with _$OnboardingContentConfigEntity {
  const factory OnboardingContentConfigEntity({
    @Default(OnboardingWelcomeConfigEntity()) OnboardingWelcomeConfigEntity welcome,
    @Default(OnboardingNameConfigEntity()) OnboardingNameConfigEntity name,
    @Default(OnboardingAgeConfigEntity()) OnboardingAgeConfigEntity age,
    @Default(OnboardingPathsConfigEntity()) OnboardingPathsConfigEntity paths,
    @Default(OnboardingBrainConfigEntity()) OnboardingBrainConfigEntity brain,
    @Default(OnboardingHabitConfigEntity()) OnboardingHabitConfigEntity habit,
    @Default(OnboardingNotifConfigEntity()) OnboardingNotifConfigEntity notif,
    @Default(OnboardingPickConfigEntity()) OnboardingPickConfigEntity pick,
    @Default(OnboardingThemeConfigEntity()) OnboardingThemeConfigEntity theme,

    /// Show the FULL paywall right after onboarding completes (admin toggle
    /// on the Onboarding Config page). Off when unset/unseeded.
    @Default(false) bool showPaywallAfterOnboarding,

    //* Onboarding v3 sections (taxonomy-driven flow)
    @Default(OnboardingDesireConfigEntity()) OnboardingDesireConfigEntity desire,
    @Default(OnboardingHowConfigEntity()) OnboardingHowConfigEntity how,
    @Default(OnboardingReminderConfigEntity()) OnboardingReminderConfigEntity reminder,
    @Default(OnboardingLoadingConfigEntity()) OnboardingLoadingConfigEntity loading,
  }) = _OnboardingContentConfigEntity;
}
