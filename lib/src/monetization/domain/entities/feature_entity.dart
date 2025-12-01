part of '../../monetization.dart';

@freezed
abstract class FeatureEntity with _$FeatureEntity {
  const factory FeatureEntity({
    @Default('') String id,
    @Default('') String featureKey,
    @Default(false) bool isActive,
  }) = _FeatureEntity;

  factory FeatureEntity.fromJson(Map<String, dynamic> json) => _$FeatureEntityFromJson(json);
}
