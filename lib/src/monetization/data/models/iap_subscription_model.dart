part of '../../monetization.dart';

@freezed
abstract class IapSubscriptionModel with _$IapSubscriptionModel {
  const factory IapSubscriptionModel({
    @Default('') String id,
    @Default('') String userId,
    @Default(PaymentPlatform.google) PaymentPlatform platform,
    @Default('') String productId,
    @Default('') String anchorId,
    @Default(SubscriptionStatus.active) SubscriptionStatus status,
    @Default(false) bool autoRenewing,
    @Default(false) bool isTrial,
    DateTime? currentPeriodStart,
    DateTime? currentPeriodEnd,
    DateTime? lastVerifiedAt,
    DateTime? lastEventAt,
  }) = _IapSubscriptionModel;

  factory IapSubscriptionModel.fromJson(Map<String, dynamic> json) => _$IapSubscriptionModelFromJson(json);
}

enum SubscriptionStatus {
  @JsonValue('active')
  active,
  @JsonValue('expired')
  expired,
  @JsonValue('grace') // gia hạn trễ, vẫn còn premium
  grace,
  @JsonValue('on_hold') // payment fail quá nhiều lần, permission bị tạm khóa
  onHold,
  @JsonValue('canceled') // user đã tắt auto-renew, nhưng vẫn còn dùng đến cuối kỳ
  canceled,
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
