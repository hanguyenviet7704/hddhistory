part of '../../onboarding.dart';

/// Content for the onboarding v3 "Reminder" screen.
@freezed
abstract class OnboardingReminderConfigEntity with _$OnboardingReminderConfigEntity {
  const factory OnboardingReminderConfigEntity({
    @Default(BaseMultiLanguage()) BaseMultiLanguage heading,
    @Default(BaseMultiLanguage()) BaseMultiLanguage headingHighlight,
    @Default(BaseMultiLanguage()) BaseMultiLanguage subtitle,
    @Default(BaseMultiLanguage()) BaseMultiLanguage timeSectionLabel,
    @Default([]) List<OnboardingReminderPresetEntity> presets,
    @Default(BaseMultiLanguage()) BaseMultiLanguage ctaLabel,
    @Default(BaseMultiLanguage()) BaseMultiLanguage secondaryCtaLabel,
  }) = _OnboardingReminderConfigEntity;
}

@freezed
abstract class OnboardingReminderPresetEntity with _$OnboardingReminderPresetEntity {
  const factory OnboardingReminderPresetEntity({
    @Default(BaseMultiLanguage()) BaseMultiLanguage label,
    @Default('') String time,
  }) = _OnboardingReminderPresetEntity;
}
