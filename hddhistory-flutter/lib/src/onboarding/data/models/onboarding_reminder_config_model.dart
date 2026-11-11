part of '../../onboarding.dart';

@freezed
abstract class OnboardingReminderConfigModel with _$OnboardingReminderConfigModel {
  const factory OnboardingReminderConfigModel({
    @Default(BaseMultiLanguage()) BaseMultiLanguage heading,
    @Default(BaseMultiLanguage()) BaseMultiLanguage headingHighlight,
    @Default(BaseMultiLanguage()) BaseMultiLanguage subtitle,
    @Default(BaseMultiLanguage()) BaseMultiLanguage timeSectionLabel,
    @Default([]) List<OnboardingReminderPresetModel> presets,
    @Default(BaseMultiLanguage()) BaseMultiLanguage ctaLabel,
    @Default(BaseMultiLanguage()) BaseMultiLanguage secondaryCtaLabel,
  }) = _OnboardingReminderConfigModel;

  factory OnboardingReminderConfigModel.fromJson(Map<String, dynamic> json) => _$OnboardingReminderConfigModelFromJson(json);
}

extension OnboardingReminderConfigModelExtension on OnboardingReminderConfigModel {
  OnboardingReminderConfigEntity toEntity() => OnboardingReminderConfigEntity(
    heading: heading,
    headingHighlight: headingHighlight,
    subtitle: subtitle,
    timeSectionLabel: timeSectionLabel,
    presets: presets.map((preset) => preset.toEntity()).toList(),
    ctaLabel: ctaLabel,
    secondaryCtaLabel: secondaryCtaLabel,
  );
}

@freezed
abstract class OnboardingReminderPresetModel with _$OnboardingReminderPresetModel {
  const factory OnboardingReminderPresetModel({
    @Default(BaseMultiLanguage()) BaseMultiLanguage label,
    @Default('') String time,
  }) = _OnboardingReminderPresetModel;

  factory OnboardingReminderPresetModel.fromJson(Map<String, dynamic> json) => _$OnboardingReminderPresetModelFromJson(json);
}

extension OnboardingReminderPresetModelExtension on OnboardingReminderPresetModel {
  OnboardingReminderPresetEntity toEntity() => OnboardingReminderPresetEntity(label: label, time: time);
}
