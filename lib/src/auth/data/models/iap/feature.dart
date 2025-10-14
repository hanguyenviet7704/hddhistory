part of '../models.dart';

@freezed
abstract class Feature with _$Feature {
  const factory Feature({
    @Default('') String id,
    @Default('') String featureKey,
    @Default(false) bool isActive,
  }) = _Feature;

  factory Feature.fromJson(Map<String, dynamic> json) => _$FeatureFromJson(json);
}
