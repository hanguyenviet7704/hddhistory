part of '../../onboard_branching.dart';

@freezed
abstract class OnboardingScenarioBranchingEntity with _$OnboardingScenarioBranchingEntity {
  const factory OnboardingScenarioBranchingEntity({
    @Default('') String entrySceneId,
    @Default([]) List<OnboardingScenarioSceneEntity> scenes,
  }) = _OnboardingScenarioBranchingEntity;

  factory OnboardingScenarioBranchingEntity.fromJson(Map<String, dynamic> json) => _$OnboardingScenarioBranchingEntityFromJson(json);
}

@freezed
abstract class OnboardingScenarioSceneEntity with _$OnboardingScenarioSceneEntity {
  const factory OnboardingScenarioSceneEntity({
    @Default('') String id,
    @Default([]) List<OnboardingScenarioContentItemEntity> contents,
  }) = _OnboardingScenarioSceneEntity;

  factory OnboardingScenarioSceneEntity.fromJson(Map<String, dynamic> json) => _$OnboardingScenarioSceneEntityFromJson(json);
}

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

@freezed
abstract class OnboardingScenarioActivationEntity with _$OnboardingScenarioActivationEntity {
  const factory OnboardingScenarioActivationEntity({
    @Default(0) int id,
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @Default(BaseMultiLanguage()) BaseMultiLanguage description,
    @Default(OnboardingScenarioActivationContentEntity()) OnboardingScenarioActivationContentEntity content,
  }) = _OnboardingScenarioActivationEntity;

  factory OnboardingScenarioActivationEntity.fromJson(Map<String, dynamic> json) => _$OnboardingScenarioActivationEntityFromJson(json);
}

@freezed
abstract class OnboardingScenarioActivationContentEntity with _$OnboardingScenarioActivationContentEntity {
  const factory OnboardingScenarioActivationContentEntity({
    @Default('') String icon,
    @Default([]) List<OnboardOptionEntity> labels,
  }) = _OnboardingScenarioActivationContentEntity;

  factory OnboardingScenarioActivationContentEntity.fromJson(Map<String, dynamic> json) => _$OnboardingScenarioActivationContentEntityFromJson(json);
}

@freezed
abstract class OnboardingScenarioBranchEntity with _$OnboardingScenarioBranchEntity {
  const factory OnboardingScenarioBranchEntity({
    @Default(BaseMultiLanguage()) BaseMultiLanguage subQuestion,
    @Default(BaseMultiLanguage()) BaseMultiLanguage question,
    @Default([]) List<OnboardingScenarioBranchOptionEntity> options,
  }) = _OnboardingScenarioBranchEntity;

  factory OnboardingScenarioBranchEntity.fromJson(Map<String, dynamic> json) => _$OnboardingScenarioBranchEntityFromJson(json);
}

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

@freezed
abstract class OnboardingScenarioFixedEntity with _$OnboardingScenarioFixedEntity {
  const factory OnboardingScenarioFixedEntity({
    @Default(BaseMultiLanguage()) BaseMultiLanguage subQuestion,
    @Default(BaseMultiLanguage()) BaseMultiLanguage question,
    @Default([]) List<OnboardOptionEntity> options,
  }) = _OnboardingScenarioFixedEntity;

  factory OnboardingScenarioFixedEntity.fromJson(Map<String, dynamic> json) => _$OnboardingScenarioFixedEntityFromJson(json);
}

@freezed
abstract class OnboardingScenarioPersonAdmireEntity with _$OnboardingScenarioPersonAdmireEntity {
  const factory OnboardingScenarioPersonAdmireEntity({
    @Default(BaseMultiLanguage()) BaseMultiLanguage subQuestion,
    @Default(BaseMultiLanguage()) BaseMultiLanguage question,
    @Default([]) List<OnboardingScenarioPersonOptionEntity> options,
  }) = _OnboardingScenarioPersonAdmireEntity;

  factory OnboardingScenarioPersonAdmireEntity.fromJson(Map<String, dynamic> json) => _$OnboardingScenarioPersonAdmireEntityFromJson(json);
}

@freezed
abstract class OnboardingScenarioPersonOptionEntity with _$OnboardingScenarioPersonOptionEntity {
  const factory OnboardingScenarioPersonOptionEntity({
    String? image,
    @Default('') String name,
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @Default(BaseMultiLanguage()) BaseMultiLanguage subTitle,
  }) = _OnboardingScenarioPersonOptionEntity;

  factory OnboardingScenarioPersonOptionEntity.fromJson(Map<String, dynamic> json) => _$OnboardingScenarioPersonOptionEntityFromJson(json);
}
