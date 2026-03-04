part of '../../onboard_branching.dart';

@freezed
abstract class OnboardingScenarioBranchModel with _$OnboardingScenarioBranchModel {
  const factory OnboardingScenarioBranchModel({
    @Default(BaseMultiLanguage()) BaseMultiLanguage subQuestion,
    @Default(BaseMultiLanguage()) BaseMultiLanguage question,
    @Default([]) List<OnboardingScenarioBranchOptionModel> options,
  }) = _OnboardingScenarioBranchModel;

  factory OnboardingScenarioBranchModel.fromJson(Map<String, dynamic> json) => _$OnboardingScenarioBranchModelFromJson(json);
}

extension OnboardingScenarioBranchModelExtension on OnboardingScenarioBranchModel {
  OnboardingScenarioBranchEntity toEntity() => OnboardingScenarioBranchEntity(
        subQuestion: subQuestion,
        question: question,
        options: options.map((option) => option.toEntity()).toList(),
      );
}
