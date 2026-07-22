part of '../../onboarding.dart';

/// Content for the Brain science screen (screen 6 of 9). `unlockedPillTemplate`
/// contains `{n}` (picked path count), `moreTemplate` contains `{m}`
/// (remaining path count). No `ctaLabel` field in the API contract — the
/// continue button copy is a local constant. `imageUrl` is an OPTIONAL
/// admin-provided network image for the hex diagram; when empty the screen
/// is expected to fall back to a bundled/procedural hex diagram (this config
/// section has no consuming UI yet — see onboard_v2 for the shipped flow).
@freezed
abstract class OnboardingBrainConfigEntity with _$OnboardingBrainConfigEntity {
  const factory OnboardingBrainConfigEntity({
    @Default(BaseMultiLanguage()) BaseMultiLanguage heading,
    @Default(BaseMultiLanguage()) BaseMultiLanguage headingHighlight,
    @Default(BaseMultiLanguage()) BaseMultiLanguage headingSuffix,
    @Default(BaseMultiLanguage()) BaseMultiLanguage unlockedPillTemplate,
    @Default(BaseMultiLanguage()) BaseMultiLanguage moreTemplate,
    @Default('') String imageUrl,
  }) = _OnboardingBrainConfigEntity;
}
