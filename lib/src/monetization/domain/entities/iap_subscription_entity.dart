part of '../../monetization.dart';

@freezed
abstract class IapSubscriptionEntity with _$IapSubscriptionEntity {
  const factory IapSubscriptionEntity({
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
  }) = _IapSubscriptionEntity;

  factory IapSubscriptionEntity.fromJson(Map<String, dynamic> json) => _$IapSubscriptionEntityFromJson(json);
}

extension IapSubscriptionEntityX on IapSubscriptionEntity {
  IapProductEntity get product {
    List<IapProductEntity> products = AppDI.injector.get<IapCubit>().state.iapProducts;
    return products.firstWhere((element) => element.productId == productId);
  }
}