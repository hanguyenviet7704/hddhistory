part of '../../onboard_branching.dart';

@freezed
abstract class OnboardingScenarioPersonAdmireModel with _$OnboardingScenarioPersonAdmireModel {
  const factory OnboardingScenarioPersonAdmireModel({
    @Default(BaseMultiLanguage()) BaseMultiLanguage subQuestion,
    @Default(BaseMultiLanguage()) BaseMultiLanguage question,
    @Default([]) List<OnboardingScenarioPersonOptionModel> options,
  }) = _OnboardingScenarioPersonAdmireModel;

  factory OnboardingScenarioPersonAdmireModel.fromJson(Map<String, dynamic> json) => _$OnboardingScenarioPersonAdmireModelFromJson(json);
}

extension OnboardingScenarioPersonAdmireModelExtension on OnboardingScenarioPersonAdmireModel {
  OnboardingScenarioPersonAdmireEntity toEntity() => OnboardingScenarioPersonAdmireEntity(
        subQuestion: subQuestion,
        question: question,
        options: options.map((option) => option.toEntity()).toList(),
      );
}
