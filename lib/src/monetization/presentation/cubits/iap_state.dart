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

  /// Opened from the daily-quota locked card's "Go Premium" CTA. Distinct from
  /// [inLesson] because the sheet's `source` set names it (`keypoint_locked`)
  /// — the funnel must tell "hit the free-limit wall" apart from the swipe
  /// gate.
  keypointLocked,
  habit,
  theme,

  /// Tapped "Create a lesson" in My lessons (Profile → learning import).
  /// Distinct from [profile] so the funnel can tell "came for the import
  /// feature" apart from "wandered into settings".
  learningImport,

  /// Opened right after the onboarding handoff (admin Onboarding Config
  /// toggle `showPaywallAfterOnboarding`).
  onboarding,

  /// Opened by the win-back gate: the reader closed the full paywall without
  /// buying, and this is the compact sheet that follows. App-initiated, so it
  /// reports as `system` rather than as anything the reader chose.
  winBack,

  /// Tapped the gold crown disc in the Home header. Its own value rather than
  /// [other] so a config can one day give Home its own paywall variant, and so
  /// this open never lands in the catch-all bucket. Its spec `source` collapses
  /// to `upgrade` alongside [settingPre]/[profile] — the Home-specific count
  /// comes from the `home_premium_click` event instead.
  ///
  /// No server config carries a `home` key yet — `variantForEntryPoint` falls
  /// back to the FULL paywall, which is what this entry point wants anyway.
  home,
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

    /// Bumped when the win-back delay elapses and the compact sheet is due.
    ///
    /// A counter rather than a bool: two win-backs in one session would emit the
    /// same `true` twice and a BlocListener comparing states would swallow the
    /// second. Nothing reads the value itself — only that it changed.
    @Default(0) int winBackDueTick,
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

    /// Id of the LogicSale campaign that produced [iapProducts] for THIS load,
    /// or empty when none is active. Carried into `VerifyParams.logicSaleId`
    /// for a purchase started from this paywall session — see
    /// IapCubit._verifyPurchase.
    @Default('') String logicSaleId,

    /// Device-local absolute deadline for the LogicSale countdown strip,
    /// already translated from the server clock captured at fetch time (see
    /// IapCubit._logicSaleLocalDeadline). Null hides the strip: no LogicSale,
    /// its `countdown` flag was off, or its SKU override did not resolve.
    DateTime? logicSaleCountdownEndAt,
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
