part of '../../onboard_branching.dart';

@freezed
abstract class OnboardingScenarioActivationModel with _$OnboardingScenarioActivationModel {
  const factory OnboardingScenarioActivationModel({
    @Default(0) int id,
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @Default(BaseMultiLanguage()) BaseMultiLanguage description,
    @Default(OnboardingScenarioActivationContentModel()) OnboardingScenarioActivationContentModel content,
  }) = _OnboardingScenarioActivationModel;

  factory OnboardingScenarioActivationModel.fromJson(Map<String, dynamic> json) => _$OnboardingScenarioActivationModelFromJson(json);
}

extension OnboardingScenarioActivationModelExtension on OnboardingScenarioActivationModel {
  OnboardingScenarioActivationEntity toEntity() => OnboardingScenarioActivationEntity(
        id: id,
        title: title,
        description: description,
        content: content.toEntity(),
      );
}

