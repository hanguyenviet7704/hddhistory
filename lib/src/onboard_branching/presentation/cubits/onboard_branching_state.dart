
part of '../../onboard_branching.dart';

enum OnboardBranchingStatus { initial, loading, success, failure }

@freezed
abstract class OnboardBranchingState with _$OnboardBranchingState {
  const factory OnboardBranchingState({
    @Default(OnboardBranchingStatus.initial) OnboardBranchingStatus status,
    @Default(OnboardingScenarioBranchingEntity()) OnboardingScenarioBranchingEntity onboardScenarioData,
    @Default(0) int currentSceneIndex,
    @Default([]) List<OnboardingScenarioBranchOptionEntity> selectedBranchOptions,
    String? errorMessage,
  }) = _OnboardBranchingState;

  factory OnboardBranchingState.initial() => OnboardBranchingState();

  factory OnboardBranchingState.fromJson(Map<String, dynamic> json) => _$OnboardBranchingStateFromJson(json);
}

