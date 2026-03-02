part of '../../onboard_branching.dart';

@freezed
abstract class OnboardingScenarioBranchingEntity with _$OnboardingScenarioBranchingEntity {
  const factory OnboardingScenarioBranchingEntity({
    @Default('') String id,
    @Default('') String entrySceneId,
    @Default([]) List<OnboardingScenarioSceneEntity> scenes,
  }) = _OnboardingScenarioBranchingEntity;

  factory OnboardingScenarioBranchingEntity.fromJson(Map<String, dynamic> json) => _$OnboardingScenarioBranchingEntityFromJson(json);
}

extension OnboardingScenarioBranchingEntityExtension on OnboardingScenarioBranchingEntity {
  OnboardingScenarioSceneEntity get entryScene => scenes.firstWhere((scene) => scene.id == entrySceneId, orElse: () => OnboardingScenarioSceneEntity());

  OnboardingScenarioSceneEntity getSceneById(String id) => scenes.firstWhere((scene) => scene.id == id, orElse: () => OnboardingScenarioSceneEntity());

  bool hasScene(String id) => scenes.any((scene) => scene.id == id);
  bool get hasEntryScene => entrySceneId.trim().isNotEmpty && hasScene(entrySceneId.trim());
}
