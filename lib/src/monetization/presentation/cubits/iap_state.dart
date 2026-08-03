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

  /// Opened mid-keypoint by the `inLessonPaywall` gate, when the reader swipes
  /// off the first card.
  inLesson,
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
    // Promo code. `appliedVoucherCode` is empty until the server validates a
    // code; the SKU swap it authorised is kept so the paywall can re-apply it
    // whenever the product list reloads.
    @Default('') String appliedVoucherCode,
    // Code kept purely for affiliate attribution. Set whenever the affiliate
    // service RECOGNISED the code, which includes the case where it did not
    // lower the price (`not_better`) and so never became
    // [appliedVoucherCode]. Their spec wants the referral credited either way,
    // so this — not [appliedVoucherCode] — is what verify sends up. Keeping the
    // two apart matters: [appliedVoucherCode] drives the SKU swap and the
    // "applied" chip, and showing that chip for a code that changed no price
    // would contradict the message the sheet just displayed.
    @Default('') String attributedVoucherCode,
    @Default(<VoucherProductMappingEntity>[]) List<VoucherProductMappingEntity> voucherProducts,
    @Default(false) bool isValidatingVoucher,
    @Default(VoucherRejectReason.unknown) VoucherRejectReason voucherRejectReason,
    @Default(false) bool hasVoucherFeedback,
  }) = _IapState;

  factory IapState.initial() => IapState();

  factory IapState.fromJson(Map<String, dynamic> json) => _$IapStateFromJson(json);
}

extension IapStateVoucherX on IapState {
  bool get hasAppliedVoucher => appliedVoucherCode.isNotEmpty;

  /// base SKU → discounted SKU authorised by the applied code.
  Map<String, String> get voucherSwapMap => {
    for (final item in voucherProducts) item.baseProductId: item.targetProductId,
  };

  /// Rewrites a strategy's product ids through the applied code. Ids without a
  /// mapping are left untouched — a code only ever replaces the plans it
  /// explicitly covers.
  List<String> applyVoucherSwap(List<String> productIds) {
    if (!hasAppliedVoucher) return productIds;
    final swap = voucherSwapMap;
    return [for (final id in productIds) swap[id] ?? id];
  }
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
