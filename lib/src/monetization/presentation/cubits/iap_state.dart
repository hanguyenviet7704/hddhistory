part of '../../monetization.dart';

enum MonetizationStatus { initial, loading, restoring, purchasing, purchaseSuccess, success, failure }

enum PurchaseAction { none, purchase, restore }

enum PurchaseOrigin { none, paywall, other }

enum PaywallEntryPoint {
  settingPre,
  profile,
  manageSubscription,
  autoOpen,
  courseRoadmap,
  habit,
  theme,
  other,
}

@freezed
abstract class IapState with _$IapState {
  const factory IapState({
    @Default(MonetizationStatus.initial) MonetizationStatus status,
    @Default(false) bool isAvailable,
    @Default([]) List<IapProductEntity> iapProducts,
    @Default('') String selectedProductId,
    ResolvedPaywallStrategyEntity? resolvedPaywallStrategy,
    @Default(PaywallContentEntity()) PaywallContentEntity paywallContent,
    @Default('') String paywallStrategySignature,
    @Default(PurchaseAction.none) PurchaseAction lastAction,
    @Default(PurchaseOrigin.none) PurchaseOrigin lastOrigin,
    String? errorMessage,
  }) = _IapState;

  factory IapState.initial() => IapState();

  factory IapState.fromJson(Map<String, dynamic> json) => _$IapStateFromJson(json);
}

extension IapStateX on IapState {
  IapProductEntity get bestDealProduct {
    for (final item in iapProducts) {
      if (item.bestDeal) return item;
    }
    return iapProducts.isEmpty ? const IapProductEntity() : iapProducts.first;
  }

  IapProductEntity get selectedProduct {
    for (final item in iapProducts) {
      if (item.id == selectedProductId) return item;
    }
    return iapProducts.isEmpty ? const IapProductEntity() : iapProducts.first;
  }
}
