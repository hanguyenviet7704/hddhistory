part of '../../monetization.dart';

class ResolvePaywallStrategyParams {
  final PaywallConfigEntity config;
  final PaymentPlatform platform;
  final DateTime nowUtc;

  /// Where the paywall is being opened from. Decides nothing about WHICH
  /// strategy wins — only which of that strategy's SKU lists is rendered.
  final PaywallEntryPoint entryPoint;

  const ResolvePaywallStrategyParams({
    required this.config,
    required this.platform,
    required this.nowUtc,
    this.entryPoint = PaywallEntryPoint.other,
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

    // Which strategy wins is decided exactly as before; the entry point only
    // narrows the winner's SKU list afterwards.
    final variant = params.config.variantForEntryPoint(params.entryPoint.name);

    final event = saleStrategy.saleEvent;
    // Sale events restyle the FULL paywall only (spec owner's ruling). The
    // compact sheet carries its own numbers in `compactPaywall`, so a compact
    // entry point resolves straight to the default strategy even mid-sale.
    if (variant != PaywallProductVariant.compact && _isActiveEvent(event, params.nowUtc)) {
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

  /// Enabled and inside its window is all it takes. `appliesTo` is deliberately
  /// NOT consulted any more: with a single audience its only remaining power
  /// was to make a correctly configured campaign show to nobody.
  bool _isActiveEvent(PaywallSaleEventStrategyEntity? event, DateTime nowUtc) {
    if (event == null || !event.enabled || event.startAtUtc == null || event.endAtUtc == null) return false;
    final now = nowUtc.toUtc();
    return !now.isBefore(event.startAtUtc!) && !now.isAfter(event.endAtUtc!);
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
