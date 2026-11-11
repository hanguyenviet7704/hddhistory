part of '../../onboarding.dart';

/// Content for the Pick course screen (screen 9 of 9). The course list itself
/// is dynamic (fetched via the existing courses use case, not part of this
/// config) — this section only carries the surrounding copy.
@freezed
abstract class OnboardingPickConfigEntity with _$OnboardingPickConfigEntity {
  const factory OnboardingPickConfigEntity({
    @Default(BaseMultiLanguage()) BaseMultiLanguage eyebrow,
    @Default(BaseMultiLanguage()) BaseMultiLanguage heading,
    @Default(BaseMultiLanguage()) BaseMultiLanguage headingHighlight,
    @Default(BaseMultiLanguage()) BaseMultiLanguage label,
    @Default(BaseMultiLanguage()) BaseMultiLanguage primaryCta,
    @Default(BaseMultiLanguage()) BaseMultiLanguage secondaryCta,
    @Default('') String iconUrl,
  }) = _OnboardingPickConfigEntity;
}
