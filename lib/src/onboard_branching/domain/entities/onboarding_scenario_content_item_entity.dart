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

extension OnboardingScenarioContentItemEntityExtension on OnboardingScenarioContentItemEntity {
  bool get hasValidPayload {
    return switch (type) {
      OnboardingContentType.fact => fact != null,
      OnboardingContentType.activation => activation != null,
      OnboardingContentType.branch => branch != null && branch!.options.isNotEmpty,
      OnboardingContentType.fixed => fixed != null && fixed!.options.isNotEmpty,
      OnboardingContentType.personAdmire => personAdmire != null && personAdmire!.options.isNotEmpty,
      OnboardingContentType.unknown => false,
    };
  }

  String get trackingType {
    return switch (type) {
      OnboardingContentType.fact => 'fact',
      OnboardingContentType.activation => 'activation',
      OnboardingContentType.branch => 'branch',
      OnboardingContentType.fixed => 'fixed',
      OnboardingContentType.personAdmire => 'person_admire',
      OnboardingContentType.unknown => 'unknown',
    };
  }
}
