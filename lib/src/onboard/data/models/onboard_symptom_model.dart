part of '../../onboard.dart';

@freezed
abstract class OnboardSymptomModel with _$OnboardSymptomModel {
  const factory OnboardSymptomModel({
    @Default('') String key,
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @Default('') String trackingLabel,
    @Default(0) int order,
  }) = _OnboardSymptomModel;

  factory OnboardSymptomModel.fromJson(Map<String, dynamic> json) => _$OnboardSymptomModelFromJson(json);
}

extension OnboardSymptomModelExtension on OnboardSymptomModel {
  // NOTE: `order` must be qualified with `this.` here — `package:injectable`
  // exports a top-level `const order = Order(0);` that otherwise shadows the
  // instance getter inside this extension body.
  OnboardSymptomEntity toEntity() => OnboardSymptomEntity(
    key: key,
    title: title,
    trackingLabel: trackingLabel,
    order: this.order,
  );
}
