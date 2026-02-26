part of '../../onboard_branching.dart';

@freezed
abstract class OnboardingScenarioSceneEntity with _$OnboardingScenarioSceneEntity {
  const factory OnboardingScenarioSceneEntity({
    @Default('') String id,
    @Default([]) List<OnboardingScenarioContentItemEntity> contents,
  }) = _OnboardingScenarioSceneEntity;

  factory OnboardingScenarioSceneEntity.fromJson(Map<String, dynamic> json) => _$OnboardingScenarioSceneEntityFromJson(json);
}
