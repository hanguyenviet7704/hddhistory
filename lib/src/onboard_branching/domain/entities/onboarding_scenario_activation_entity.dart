part of '../../onboard_branching.dart';

@freezed
abstract class OnboardingScenarioActivationEntity with _$OnboardingScenarioActivationEntity {
  const factory OnboardingScenarioActivationEntity({
    @Default(0) int id,
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @Default(BaseMultiLanguage()) BaseMultiLanguage description,
    @Default(OnboardingScenarioActivationContentEntity()) OnboardingScenarioActivationContentEntity content,
  }) = _OnboardingScenarioActivationEntity;

  factory OnboardingScenarioActivationEntity.fromJson(Map<String, dynamic> json) => _$OnboardingScenarioActivationEntityFromJson(json);
}
