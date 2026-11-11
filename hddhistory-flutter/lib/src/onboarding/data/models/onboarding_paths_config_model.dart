part of '../../onboarding.dart';

@freezed
abstract class OnboardingPathsConfigModel with _$OnboardingPathsConfigModel {
  const factory OnboardingPathsConfigModel({
    @Default(BaseMultiLanguage()) BaseMultiLanguage heading,
    @Default(BaseMultiLanguage()) BaseMultiLanguage headingHighlight,
    @Default(BaseMultiLanguage()) BaseMultiLanguage helper,
    @Default(0) int maxSelect,
    @Default([]) List<OnboardingPathItemModel> items,
  }) = _OnboardingPathsConfigModel;

  factory OnboardingPathsConfigModel.fromJson(Map<String, dynamic> json) => _$OnboardingPathsConfigModelFromJson(json);
}

extension OnboardingPathsConfigModelExtension on OnboardingPathsConfigModel {
  OnboardingPathsConfigEntity toEntity() => OnboardingPathsConfigEntity(
    heading: heading,
    headingHighlight: headingHighlight,
    helper: helper,
    maxSelect: maxSelect,
    items: items.map((item) => item.toEntity()).toList(),
  );
}

@freezed
abstract class OnboardingPathItemModel with _$OnboardingPathItemModel {
  const factory OnboardingPathItemModel({
    @Default('') String key,
    @Default(BaseMultiLanguage()) BaseMultiLanguage label,
    @Default('') String iconKey,
    @Default('') String iconUrl,
    @Default(0) int order,
    @Default([]) List<OnboardingPathSymptomModel> symptoms,
  }) = _OnboardingPathItemModel;

  factory OnboardingPathItemModel.fromJson(Map<String, dynamic> json) => _$OnboardingPathItemModelFromJson(json);
}

extension OnboardingPathItemModelExtension on OnboardingPathItemModel {
  // NOTE: `order` must be qualified with `this.` here — `package:injectable`
  // exports a top-level `const order = Order(0);` that otherwise shadows the
  // instance getter inside this extension body (see onboard_path_model.dart
  // for the same gotcha).
  OnboardingPathItemEntity toEntity() => OnboardingPathItemEntity(
    key: key,
    label: label,
    iconKey: iconKey,
    iconUrl: iconUrl,
    order: this.order,
    symptoms: symptoms.map((symptom) => symptom.toEntity()).toList(),
  );
}

@freezed
abstract class OnboardingPathSymptomModel with _$OnboardingPathSymptomModel {
  const factory OnboardingPathSymptomModel({
    @Default('') String key,
    @Default(BaseMultiLanguage()) BaseMultiLanguage label,
    @Default(0) int order,
  }) = _OnboardingPathSymptomModel;

  factory OnboardingPathSymptomModel.fromJson(Map<String, dynamic> json) => _$OnboardingPathSymptomModelFromJson(json);
}

extension OnboardingPathSymptomModelExtension on OnboardingPathSymptomModel {
  // See the `this.order` note above — same injectable top-level shadowing.
  OnboardingPathSymptomEntity toEntity() => OnboardingPathSymptomEntity(
    key: key,
    label: label,
    order: this.order,
  );
}
