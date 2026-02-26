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

extension OnboardingScenarioContentItemModelExtension on OnboardingScenarioContentItemModel {
  OnboardingScenarioContentItemEntity toEntity() => OnboardingScenarioContentItemEntity(
        id: id,
        type: type,
        fact: fact?.toEntity(),
        activation: activation?.toEntity(),
        branch: branch?.toEntity(),
        fixed: fixed?.toEntity(),
        personAdmire: personAdmire?.toEntity(),
      );
}

enum OnboardingContentType {
  @JsonValue('fact')
  fact,
  @JsonValue('activation')
  activation,
  @JsonValue('branch')
  branch,
  @JsonValue('fixed')
  fixed,
  @JsonValue('person_admire')
  personAdmire,
  @JsonValue('unknown')
  unknown,
}
