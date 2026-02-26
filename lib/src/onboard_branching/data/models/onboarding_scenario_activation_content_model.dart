part of '../../onboard_branching.dart';

@freezed
abstract class OnboardingScenarioActivationContentModel with _$OnboardingScenarioActivationContentModel {
  const factory OnboardingScenarioActivationContentModel({
    @Default('') String icon,
    @Default([]) List<OnboardOptionModel> labels,
  }) = _OnboardingScenarioActivationContentModel;

  factory OnboardingScenarioActivationContentModel.fromJson(Map<String, dynamic> json) => _$OnboardingScenarioActivationContentModelFromJson(json);
}
