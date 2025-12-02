part of '../../monetization.dart';

@freezed
abstract class IapProductEntity with _$IapProductEntity {
  const factory IapProductEntity({
    @Default('') String id,
    @Default('') String productId,
    @Default(PaymentPlatform.google) PaymentPlatform platform,
    @Default('') String title,
    @Default('') String description,
    @Default('') String price,
    @Default(0) double rawPrice,
    @Default('') String currencyCode,
    @Default('') String currencySymbol,
  }) = _IapProductEntity;

  factory IapProductEntity.fromJson(Map<String, dynamic> json) => _$IapProductEntityFromJson(json);
}
