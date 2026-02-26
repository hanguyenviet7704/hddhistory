part of '../../onboard_branching.dart';

@freezed
abstract class OnboardingScenarioBranchingEntity with _$OnboardingScenarioBranchingEntity {
  const factory OnboardingScenarioBranchingEntity({
    @Default('') String entrySceneId,
    @Default([]) List<OnboardingScenarioSceneEntity> scenes,
  }) = _OnboardingScenarioBranchingEntity;

  factory OnboardingScenarioBranchingEntity.fromJson(Map<String, dynamic> json) => _$OnboardingScenarioBranchingEntityFromJson(json);
}
