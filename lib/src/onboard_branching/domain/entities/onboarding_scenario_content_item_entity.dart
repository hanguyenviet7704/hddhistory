part of '../../onboard_branching.dart';

@freezed
abstract class OnboardingScenarioContentItemEntity with _$OnboardingScenarioContentItemEntity {
  const factory OnboardingScenarioContentItemEntity({
    @Default(0) int id,
    @JsonKey(unknownEnumValue: OnboardingContentType.unknown) @Default(OnboardingContentType.unknown) OnboardingContentType type,
    OnboardOptionEntity? fact,
    OnboardingScenarioActivationEntity? activation,
    OnboardingScenarioBranchEntity? branch,
    OnboardingScenarioFixedEntity? fixed,
    OnboardingScenarioPersonAdmireEntity? personAdmire,
  }) = _OnboardingScenarioContentItemEntity;

  factory OnboardingScenarioContentItemEntity.fromJson(Map<String, dynamic> json) => _$OnboardingScenarioContentItemEntityFromJson(json);
}
