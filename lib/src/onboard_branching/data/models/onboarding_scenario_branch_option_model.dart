part of '../../onboard_branching.dart';

@freezed
abstract class OnboardingScenarioBranchOptionModel with _$OnboardingScenarioBranchOptionModel {
  const factory OnboardingScenarioBranchOptionModel({
    @Default(0) int id,
    @Default(BaseMultiLanguage()) BaseMultiLanguage label,
    @Default('') String icon,
    String? nextSceneId,
    @Default([]) List<String> courses,
  }) = _OnboardingScenarioBranchOptionModel;

  factory OnboardingScenarioBranchOptionModel.fromJson(Map<String, dynamic> json) => _$OnboardingScenarioBranchOptionModelFromJson(json);
}
