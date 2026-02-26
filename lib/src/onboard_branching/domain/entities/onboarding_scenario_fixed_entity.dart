part of '../../onboard_branching.dart';

@freezed
abstract class OnboardingScenarioFixedEntity with _$OnboardingScenarioFixedEntity {
  const factory OnboardingScenarioFixedEntity({
    @Default(BaseMultiLanguage()) BaseMultiLanguage subQuestion,
    @Default(BaseMultiLanguage()) BaseMultiLanguage question,
    @Default([]) List<OnboardOptionEntity> options,
  }) = _OnboardingScenarioFixedEntity;

  factory OnboardingScenarioFixedEntity.fromJson(Map<String, dynamic> json) => _$OnboardingScenarioFixedEntityFromJson(json);
}
