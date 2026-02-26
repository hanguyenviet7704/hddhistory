
part of '../../onboard_branching.dart';

enum OnboardBranchingStatus { initial, loading, success, failure }

@freezed
abstract class OnboardBranchingState with _$OnboardBranchingState {
  const factory OnboardBranchingState({
    @Default(OnboardBranchingStatus.initial) OnboardBranchingStatus status,
    OnboardingScenarioBranchingEntity? selectedItem,
    String? errorMessage,
  }) = _OnboardBranchingState;

  factory OnboardBranchingState.initial() => OnboardBranchingState();

  factory OnboardBranchingState.fromJson(Map<String, dynamic> json) => _$OnboardBranchingStateFromJson(json);
}

