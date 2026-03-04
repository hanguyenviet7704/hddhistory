part of '../../onboard_branching.dart';

@freezed
abstract class OnboardingScenarioPersonAdmireEntity with _$OnboardingScenarioPersonAdmireEntity {
  const factory OnboardingScenarioPersonAdmireEntity({
    @Default(BaseMultiLanguage()) BaseMultiLanguage subQuestion,
    @Default(BaseMultiLanguage()) BaseMultiLanguage question,
    @Default([]) List<OnboardingScenarioPersonOptionEntity> options,
  }) = _OnboardingScenarioPersonAdmireEntity;

  factory OnboardingScenarioPersonAdmireEntity.fromJson(Map<String, dynamic> json) => _$OnboardingScenarioPersonAdmireEntityFromJson(json);
}
