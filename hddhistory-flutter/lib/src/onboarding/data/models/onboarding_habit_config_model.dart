part of '../../onboarding.dart';

@freezed
abstract class OnboardingHabitConfigModel with _$OnboardingHabitConfigModel {
  const factory OnboardingHabitConfigModel({
    @Default(BaseMultiLanguage()) BaseMultiLanguage heading,
    @Default(BaseMultiLanguage()) BaseMultiLanguage headingHighlight,
    @Default(BaseMultiLanguage()) BaseMultiLanguage subtitle,
    @Default(BaseMultiLanguage()) BaseMultiLanguage ctaLabel,
    @Default('') String iconUrl,
  }) = _OnboardingHabitConfigModel;

  factory OnboardingHabitConfigModel.fromJson(Map<String, dynamic> json) => _$OnboardingHabitConfigModelFromJson(json);
}

extension OnboardingHabitConfigModelExtension on OnboardingHabitConfigModel {
  OnboardingHabitConfigEntity toEntity() => OnboardingHabitConfigEntity(
    heading: heading,
    headingHighlight: headingHighlight,
    subtitle: subtitle,
    ctaLabel: ctaLabel,
    iconUrl: iconUrl,
  );
}
