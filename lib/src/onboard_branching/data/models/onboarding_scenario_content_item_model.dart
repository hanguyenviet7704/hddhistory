part of '../../onboard_branching.dart';

@freezed
abstract class OnboardingScenarioContentItemModel with _$OnboardingScenarioContentItemModel {
  const factory OnboardingScenarioContentItemModel({
    @Default(0) int id,
    @JsonKey(unknownEnumValue: OnboardingContentType.unknown) @Default(OnboardingContentType.unknown) OnboardingContentType type,
    OnboardOptionModel? fact,
    OnboardingScenarioActivationModel? activation,
    OnboardingScenarioBranchModel? branch,
    OnboardingScenarioFixedModel? fixed,
    OnboardingScenarioPersonAdmireModel? personAdmire,
  }) = _OnboardingScenarioContentItemModel;

  factory OnboardingScenarioContentItemModel.fromJson(Map<String, dynamic> json) => _$OnboardingScenarioContentItemModelFromJson(json);
}
