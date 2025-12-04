part of '../../monetization.dart';

@freezed
abstract class IapVerifyEntity with _$IapVerifyEntity {
  const factory IapVerifyEntity({
    @Default('') String id,
    @Default('') String userId,
    @Default(PaymentPlatform.google) PaymentPlatform platform,
    @Default('') String storeTransactionId,
    @Default('') String productId,
    @Default('') String orderId,
    @Default(IapPurchaseStatus.pending) IapPurchaseStatus status,
    @Default('') String rawPayload,
    @Default('') String idempotencyKey,
    DateTime? purchaseTime,
    DateTime? expiryTime,
  }) = _IapVerifyEntity;

  factory IapVerifyEntity.fromJson(Map<String, dynamic> json) => _$IapVerifyEntityFromJson(json);
}
