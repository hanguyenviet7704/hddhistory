part of '../../onboard_branching.dart';

@freezed
abstract class OnboardingScenarioSceneModel with _$OnboardingScenarioSceneModel {
  const factory OnboardingScenarioSceneModel({
    @Default('') String id,
    @Default([]) List<OnboardingScenarioContentItemModel> contents,
  }) = _OnboardingScenarioSceneModel;

  factory OnboardingScenarioSceneModel.fromJson(Map<String, dynamic> json) => _$OnboardingScenarioSceneModelFromJson(json);
}
