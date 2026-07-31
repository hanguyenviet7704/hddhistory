part of '../../onboarding.dart';

@freezed
abstract class OnboardingContentConfigModel with _$OnboardingContentConfigModel {
  const factory OnboardingContentConfigModel({
    @Default(OnboardingWelcomeConfigModel()) OnboardingWelcomeConfigModel welcome,
    @Default(OnboardingNameConfigModel()) OnboardingNameConfigModel name,
    @Default(OnboardingAgeConfigModel()) OnboardingAgeConfigModel age,
    @Default(OnboardingPathsConfigModel()) OnboardingPathsConfigModel paths,
    @Default(OnboardingBrainConfigModel()) OnboardingBrainConfigModel brain,
    @Default(OnboardingHabitConfigModel()) OnboardingHabitConfigModel habit,
    @Default(OnboardingNotifConfigModel()) OnboardingNotifConfigModel notif,
    @Default(OnboardingPickConfigModel()) OnboardingPickConfigModel pick,
    @Default(OnboardingThemeConfigModel()) OnboardingThemeConfigModel theme,
  }) = _OnboardingContentConfigModel;

  factory OnboardingContentConfigModel.fromJson(Map<String, dynamic> json) => _$OnboardingContentConfigModelFromJson(json);
}

extension OnboardingContentConfigModelExtension on OnboardingContentConfigModel {
  OnboardingContentConfigEntity toEntity() => OnboardingContentConfigEntity(
    welcome: welcome.toEntity(),
    name: name.toEntity(),
    age: age.toEntity(),
    paths: paths.toEntity(),
    brain: brain.toEntity(),
    habit: habit.toEntity(),
    notif: notif.toEntity(),
    pick: pick.toEntity(),
    theme: theme.toEntity(),
  );
}
