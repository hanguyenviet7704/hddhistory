part of '../../onboard_branching.dart';

@freezed
abstract class OnboardingScenarioBranchingModel with _$OnboardingScenarioBranchingModel {
  const factory OnboardingScenarioBranchingModel({
    @Default('') String entrySceneId,
    @Default([]) List<OnboardingScenarioSceneModel> scenes,
  }) = _OnboardingScenarioBranchingModel;

  factory OnboardingScenarioBranchingModel.fromJson(Map<String, dynamic> json) => _$OnboardingScenarioBranchingModelFromJson(json);
}

extension OnboardingScenarioBranchingModelExtension on OnboardingScenarioBranchingModel {
  OnboardingScenarioBranchingEntity toEntity() => OnboardingScenarioBranchingEntity.fromJson(toJson());
}
