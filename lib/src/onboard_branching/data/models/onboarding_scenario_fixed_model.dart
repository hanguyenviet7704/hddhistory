part of '../../onboard_branching.dart';

@freezed
abstract class OnboardingScenarioFixedModel with _$OnboardingScenarioFixedModel {
  const factory OnboardingScenarioFixedModel({
    @Default(BaseMultiLanguage()) BaseMultiLanguage subQuestion,
    @Default(BaseMultiLanguage()) BaseMultiLanguage question,
    @Default([]) List<OnboardOptionModel> options,
  }) = _OnboardingScenarioFixedModel;

  factory OnboardingScenarioFixedModel.fromJson(Map<String, dynamic> json) => _$OnboardingScenarioFixedModelFromJson(json);
}

extension OnboardingScenarioFixedModelExtension on OnboardingScenarioFixedModel {
  OnboardingScenarioFixedEntity toEntity() => OnboardingScenarioFixedEntity(
        subQuestion: subQuestion,
        question: question,
        options: options.map((option) => option.toEntity()).toList(),
      );
}
