part of '../../monetization.dart';

@freezed
abstract class FeatureModel with _$FeatureModel {
  const factory FeatureModel({
    @Default('') String id,
    @Default('') String featureKey,
    @Default(false) bool isActive,
  }) = _FeatureModel;

  factory FeatureModel.fromJson(Map<String, dynamic> json) => _$FeatureModelFromJson(json);
}

extension FeatureModelExtension on FeatureModel {
  FeatureEntity toEntity() => FeatureEntity(
    id: id,
    featureKey: featureKey,
    isActive: isActive,
  );
}