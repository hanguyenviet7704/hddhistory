part of '../../onboarding.dart';

/// Content for the Notifications screen (screen 8 of 9). There is no
/// `secondaryCta` field in the API contract — "Maybe later" is expected to be
/// a local constant on whatever consumes this section.
@freezed
abstract class OnboardingNotifConfigEntity with _$OnboardingNotifConfigEntity {
  const factory OnboardingNotifConfigEntity({
    @Default(BaseMultiLanguage()) BaseMultiLanguage heading,
    @Default(BaseMultiLanguage()) BaseMultiLanguage headingHighlight,
    @Default(BaseMultiLanguage()) BaseMultiLanguage subtitle,
    @Default(BaseMultiLanguage()) BaseMultiLanguage cardTitle,
    @Default(BaseMultiLanguage()) BaseMultiLanguage cardBody,
    @Default(BaseMultiLanguage()) BaseMultiLanguage cardTimestamp,
    @Default(BaseMultiLanguage()) BaseMultiLanguage ctaLabel,
    @Default('') String iconUrl,
  }) = _OnboardingNotifConfigEntity;
}
