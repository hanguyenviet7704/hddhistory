part of '../../monetization.dart';

@freezed
abstract class IapSubscriptionModel with _$IapSubscriptionModel {
  const factory IapSubscriptionModel({
    @Default('') String id,
    @Default('') String userId,
    @Default(PaymentPlatform.google) PaymentPlatform platform,
    @Default('') String productId,
    @Default('') String anchorId,
    @Default(PurchaseStatus.pending) PurchaseStatus status,
    @Default(false) bool autoRenewing,
    @Default(false) bool isTrial,
    DateTime? currentPeriodStart,
    DateTime? currentPeriodEnd,
    DateTime? lastVerifiedAt,
    DateTime? lastEventAt,
  }) = _IapSubscriptionModel;

  factory IapSubscriptionModel.fromJson(Map<String, dynamic> json) => _$IapSubscriptionModelFromJson(json);
}

extension IapSubscriptionModelExtension on IapSubscriptionModel {
  IapSubscriptionEntity toEntity() => IapSubscriptionEntity(
    id: id,
    userId: userId,
    platform: platform,
    productId: productId,
    anchorId: anchorId,
    status: status,
    autoRenewing: autoRenewing,
    isTrial: isTrial,
    currentPeriodStart: currentPeriodStart,
    currentPeriodEnd: currentPeriodEnd,
    lastVerifiedAt: lastVerifiedAt,
    lastEventAt: lastEventAt,
  );
}
