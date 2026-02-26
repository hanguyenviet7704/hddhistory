part of '../../onboard_branching.dart';

@freezed
abstract class OnboardingScenarioBranchOptionEntity with _$OnboardingScenarioBranchOptionEntity {
  const factory OnboardingScenarioBranchOptionEntity({
    @Default(0) int id,
    @Default(BaseMultiLanguage()) BaseMultiLanguage label,
    @Default('') String icon,
    String? nextSceneId,
    @Default([]) List<String> courses,
  }) = _OnboardingScenarioBranchOptionEntity;

  factory OnboardingScenarioBranchOptionEntity.fromJson(Map<String, dynamic> json) => _$OnboardingScenarioBranchOptionEntityFromJson(json);
}
