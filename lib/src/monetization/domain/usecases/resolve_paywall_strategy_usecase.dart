part of '../../monetization.dart';

class ResolvePaywallStrategyParams {
  final PaywallConfigEntity config;
  final PaymentPlatform platform;
  final DateTime nowUtc;

  /// Where the paywall is being opened from. Decides nothing about WHICH
  /// strategy wins — only which of that strategy's SKU lists is rendered.
  final PaywallEntryPoint entryPoint;

  /// A caller that named the surface outright (gift popup, win-back, an admin
  /// deeplink's `?variant=`), overriding the entry-point table.
  ///
  /// It has to reach THIS far. Before, the override only changed what the page
  /// DREW: the SKU list was still resolved from the table, so a forced compact
  /// sheet queried the full list and then showed its first plan — the annual one
  /// at an annual price under a "/month" suffix, with the configured compact SKU
  /// never asked for. Which reads exactly like "the admin's compact config is
  /// being ignored", and for `winBack` (a value the config has no row for, so the
  /// table answers `full`) it happened every single time.
  final PaywallProductVariant? variantOverride;

  const ResolvePaywallStrategyParams({
    required this.config,
    required this.platform,
    required this.nowUtc,
    this.entryPoint = PaywallEntryPoint.other,
    this.variantOverride,
  });
}

@lazySingleton
class ResolvePaywallStrategyUsecase {
  const ResolvePaywallStrategyUsecase();

  /// There is ONE audience. The new-user segment was removed (2026-08-08): it
  /// was derived from the app's INSTALL time, so every fresh install — every
  /// tester on a new build, and any reader who reinstalled — counted as new for
  /// the config's window and was silently excluded from campaigns aimed at
  /// default users. That is how an enabled, in-window sale event rendered the
  /// plain paywall. Everyone now resolves as `defaultUser`.
  ResolvedPaywallStrategyEntity call(ResolvePaywallStrategyParams params) {
    final saleStrategy = params.config.saleStrategy;
    if (saleStrategy == null) return _invalid('missing_sale_strategy');

    // A running sale is the only offer on screen: it FORCES the full paywall,
    // overriding both the entry-point table and a caller's `variantOverride`.
    //
    // It used to be the other way round — a compact variant sent the reader
    // past the sale to the default strategy, on the reading that "sale events
    // restyle the FULL paywall only". That is still true of the sheet's
    // numbers, but it meant a compact entry point tapped mid-campaign quoted
    // the NON-sale price while the campaign was live, i.e. the one moment the
    // app must not be caught undercutting itself. The surfaces that push the
    // compact sheet unasked (gift popup, win-back) are silenced for the
    // duration at their own call sites; this is the backstop for anything that
    // still asks.
    final saleActive = params.config.hasActiveSaleEventAt(params.nowUtc);
    final variant = saleActive
        ? PaywallProductVariant.full
        : params.variantOverride ?? params.config.variantForEntryPoint(params.entryPoint.name);

    final event = saleStrategy.saleEvent;
    if (saleActive) {
      return _fromProducts(
        strategyType: ResolvedPaywallStrategyType.saleEvent,
        products: event!.products,
        compactProducts: event.compactProducts,
        variant: variant,
        content: event.content,
        campaignId: event.campaignId,
        endAtUtc: event.endAtUtc,
        platform: params.platform,
      );
    }

    return _fromProducts(
      strategyType: ResolvedPaywallStrategyType.defaultUser,
      products: saleStrategy.defaultUser.products,
      compactProducts: saleStrategy.defaultUser.compactProducts,
      variant: variant,
      content: saleStrategy.defaultUser.content,
      platform: params.platform,
    );
  }

  ResolvedPaywallStrategyEntity _fromProducts({
    required ResolvedPaywallStrategyType strategyType,
    required List<PaywallProductReferenceEntity> products,
    required List<PaywallProductReferenceEntity> compactProducts,
    required PaywallProductVariant variant,
    required PaywallContentEntity content,
    required PaymentPlatform platform,
    String campaignId = '',
    DateTime? endAtUtc,
  }) {
    // The compact list is an override, not a requirement: an absent, empty or
    // unusable one falls back to the full list rather than failing. A SKU
    // problem in a reduced list must never be able to blank a paywall that has
    // a perfectly good full list sitting next to it.
    final compactIds = variant == PaywallProductVariant.compact //
        ? _platformProductIds(compactProducts, platform)
        : const <String>[];
    final usesCompact = _hasValidProductIds(compactIds);

    final productIds = usesCompact ? compactIds : _platformProductIds(products, platform);
    if (!_hasValidProductIds(productIds)) return _invalid('invalid_product_ids');
    return ResolvedPaywallStrategyEntity(
      strategyType: strategyType,
      isValid: true,
      // Records the variant actually rendered, not the one asked for, so a
      // silent fallback to the full list is visible in tracking instead of
      // looking like a compact paywall that happened to show three plans.
      variant: usesCompact ? PaywallProductVariant.compact : PaywallProductVariant.full,
      campaignId: campaignId,
      endAtUtc: endAtUtc,
      productIds: productIds,
      content: content,
    );
  }

  List<String> _platformProductIds(List<PaywallProductReferenceEntity> products, PaymentPlatform platform) {
    return products.map((product) {
      return switch (platform) {
        PaymentPlatform.apple => product.appleProductId,
        PaymentPlatform.google || PaymentPlatform.unknown => product.googleProductId,
      };
    }).toList();
  }

  bool _hasValidProductIds(List<String> productIds) {
    if (productIds.isEmpty) return false;
    final normalized = productIds.map((id) => id.trim()).toList();
    if (normalized.any((id) => id.isEmpty)) return false;
    return normalized.toSet().length == normalized.length;
  }

  ResolvedPaywallStrategyEntity _invalid(String reason) {
    return ResolvedPaywallStrategyEntity(
      strategyType: ResolvedPaywallStrategyType.invalid,
      invalidReason: reason,
    );
  }
}
