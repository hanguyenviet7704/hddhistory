part of '../../onboarding.dart';

/// Content for the Habit ("Sounds like you") screen (screen 7 of 9).
@freezed
abstract class OnboardingHabitConfigEntity with _$OnboardingHabitConfigEntity {
  const factory OnboardingHabitConfigEntity({
    @Default(BaseMultiLanguage()) BaseMultiLanguage heading,
    @Default(BaseMultiLanguage()) BaseMultiLanguage headingHighlight,
    @Default(BaseMultiLanguage()) BaseMultiLanguage subtitle,
    @Default(BaseMultiLanguage()) BaseMultiLanguage ctaLabel,
    @Default('') String iconUrl,
  }) = _OnboardingHabitConfigEntity;
}
