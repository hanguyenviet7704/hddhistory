part of '../../onboard_branching.dart';

@freezed
abstract class OnboardingScenarioBranchEntity with _$OnboardingScenarioBranchEntity {
  const factory OnboardingScenarioBranchEntity({
    @Default(BaseMultiLanguage()) BaseMultiLanguage subQuestion,
    @Default(BaseMultiLanguage()) BaseMultiLanguage question,
    @Default([]) List<OnboardingScenarioBranchOptionEntity> options,
  }) = _OnboardingScenarioBranchEntity;

  factory OnboardingScenarioBranchEntity.fromJson(Map<String, dynamic> json) => _$OnboardingScenarioBranchEntityFromJson(json);
}
