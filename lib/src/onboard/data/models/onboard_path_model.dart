part of '../../onboard.dart';

@freezed
abstract class OnboardPathModel with _$OnboardPathModel {
  const factory OnboardPathModel({
    @Default('') String key,
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @Default('') String shortTitle,
    @Default('') String iconKey,
    @Default('') String iconUrl,
    @Default('') String trackingLabel,
    @Default(0) int order,
    @Default([]) List<OnboardSymptomModel> symptoms,
  }) = _OnboardPathModel;

  factory OnboardPathModel.fromJson(Map<String, dynamic> json) => _$OnboardPathModelFromJson(json);
}

extension OnboardPathModelExtension on OnboardPathModel {
  // NOTE: `order` must be qualified with `this.` here — `package:injectable`
  // exports a top-level `const order = Order(0);` that otherwise shadows the
  // instance getter inside this extension body.
  OnboardPathEntity toEntity() => OnboardPathEntity(
    key: key,
    title: title,
    shortTitle: shortTitle,
    iconKey: iconKey,
    iconUrl: iconUrl,
    trackingLabel: trackingLabel,
    order: this.order,
    symptoms: symptoms.map((model) => model.toEntity()).toList(),
  );
}
