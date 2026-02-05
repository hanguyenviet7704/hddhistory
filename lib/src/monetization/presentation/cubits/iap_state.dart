part of '../../monetization.dart';

enum MonetizationStatus { initial, loading, restoring, purchasing, purchaseSuccess, success, failure }

enum PurchaseAction { none, purchase, restore }

enum PurchaseOrigin { none, paywall, other }

enum PaywallEntryPoint { courseRoadmap, other }

@freezed
abstract class IapState with _$IapState {
  const factory IapState({
    @Default(MonetizationStatus.initial) MonetizationStatus status,
    @Default(false) bool isAvailable,
    @Default([]) List<IapProductEntity> iapProducts,
    @Default('') String selectedProductId,
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
    return iapProducts.first;
  }

  IapProductEntity get selectedProduct {
    for (final item in iapProducts) {
      if (item.id == selectedProductId) return item;
    }
    return iapProducts.first;
  }
}
