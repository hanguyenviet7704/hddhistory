part of '../../onboard_branching.dart';

@freezed
abstract class OnboardingScenarioActivationContentEntity with _$OnboardingScenarioActivationContentEntity {
  const factory OnboardingScenarioActivationContentEntity({
    @Default('') String icon,
    @Default([]) List<OnboardOptionEntity> labels,
  }) = _OnboardingScenarioActivationContentEntity;

  factory OnboardingScenarioActivationContentEntity.fromJson(Map<String, dynamic> json) => _$OnboardingScenarioActivationContentEntityFromJson(json);
}
