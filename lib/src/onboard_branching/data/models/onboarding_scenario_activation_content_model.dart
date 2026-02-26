part of '../../onboard_branching.dart';

@freezed
abstract class OnboardingScenarioActivationContentModel with _$OnboardingScenarioActivationContentModel {
  const factory OnboardingScenarioActivationContentModel({
    @Default('') String icon,
    @Default([]) List<OnboardOptionModel> labels,
  }) = _OnboardingScenarioActivationContentModel;

  factory OnboardingScenarioActivationContentModel.fromJson(Map<String, dynamic> json) => _$OnboardingScenarioActivationContentModelFromJson(json);
}

extension OnboardingScenarioActivationContentModelExtension on OnboardingScenarioActivationContentModel {
  OnboardingScenarioActivationContentEntity toEntity() => OnboardingScenarioActivationContentEntity(
        icon: icon,
        labels: labels.map((label) => label.toEntity()).toList(),
      );
}
