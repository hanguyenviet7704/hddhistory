part of '../../onboard_branching.dart';

@freezed
abstract class OnboardingScenarioPersonOptionModel with _$OnboardingScenarioPersonOptionModel {
  const factory OnboardingScenarioPersonOptionModel({
    String? image,
    @Default('') String name,
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @Default(BaseMultiLanguage()) BaseMultiLanguage subTitle,
  }) = _OnboardingScenarioPersonOptionModel;

  factory OnboardingScenarioPersonOptionModel.fromJson(Map<String, dynamic> json) => _$OnboardingScenarioPersonOptionModelFromJson(json);
}

extension OnboardingScenarioPersonOptionModelExtension on OnboardingScenarioPersonOptionModel {
  OnboardingScenarioPersonOptionEntity toEntity() => OnboardingScenarioPersonOptionEntity(
        image: image,
        name: name,
        title: title,
        subTitle: subTitle,
      );
}
