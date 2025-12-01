part of '../../monetization.dart';

@freezed
abstract class IapProductEntity with _$IapProductEntity {
  const factory IapProductEntity({
    @Default('') String id,
    @Default('') String title,
    @Default('') String description,
    @Default('') String price,
    @Default(0) double rawPrice,
    @Default('') String currencySymbol,
    @Default('') String currencyCode,
    @Default(false) bool isSubscription,
    @Default('') String planName,
    @Default(PaymentProviderEntity()) PaymentProviderEntity paymentProvider,
    @Default('') String externalPlanId,
    @Default('') String durationType,
    @Default(0) int durationValue,
    @Default('') String currency,
    @Default(false) bool isActive,
    @Default([]) List<FeatureEntity> features,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _IapProductEntity;

  factory IapProductEntity.fromJson(Map<String, dynamic> json) => _$IapProductEntityFromJson(json);
}
