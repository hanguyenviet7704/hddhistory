part of '../../onboard_branching.dart';

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
