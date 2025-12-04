part of '../../monetization.dart';

@freezed
abstract class IapVerifyModel with _$IapVerifyModel {
  const factory IapVerifyModel({
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
  }) = _IapVerifyModel;

  factory IapVerifyModel.fromJson(Map<String, dynamic> json) => _$IapVerifyModelFromJson(json);
}

enum IapPurchaseStatus {
  pending,
  paid,
  failed,
  canceled,
  refunded,
}

extension IapVerifyModelExtension on IapVerifyModel {
  IapVerifyEntity toEntity() => IapVerifyEntity(
    id: id,
    userId: userId,
    platform: platform,
    storeTransactionId: storeTransactionId,
    productId: productId,
    orderId: orderId,
    status: status,
    rawPayload: rawPayload,
    idempotencyKey: idempotencyKey,
    purchaseTime: purchaseTime,
    expiryTime: expiryTime,
  );
}
