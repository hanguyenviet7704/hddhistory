part of '../../monetization.dart';

class ResolvePaywallStrategyParams {
  final PaywallConfigEntity config;
  final PaymentPlatform platform;
  final DateTime nowUtc;
  final DateTime? installTime;
  final int storedImpressionCount;

  /// Where the paywall is being opened from. Decides nothing about WHICH
  /// strategy wins — only which of that strategy's SKU lists is rendered.
  final PaywallEntryPoint entryPoint;

  const ResolvePaywallStrategyParams({
    required this.config,
    required this.platform,
    required this.nowUtc,
    required this.installTime,
    required this.storedImpressionCount,
    this.entryPoint = PaywallEntryPoint.other,
  });
}

@lazySingleton
class ResolvePaywallStrategyUsecase {
  const ResolvePaywallStrategyUsecase();

  ResolvedPaywallStrategyEntity call(ResolvePaywallStrategyParams params) {
    final saleStrategy = params.config.saleStrategy;
    if (saleStrategy == null) return _invalid('missing_sale_strategy');

    // Which strategy wins is decided exactly as before; the entry point only
    // narrows the winner's SKU list afterwards.
    final variant = params.config.variantForEntryPoint(params.entryPoint.name);

    final segment = _segmentFor(params.installTime, params.nowUtc, saleStrategy.newUser.windowDays);
    final event = saleStrategy.saleEvent;
    // Sale events restyle the FULL paywall only (spec owner's ruling). The
    // compact sheet carries its own numbers in `compactPaywall`, so a compact
    // entry point resolves straight to the audience strategy even mid-sale.
    if (variant != PaywallProductVariant.compact && _isActiveEvent(event, segment, params.nowUtc)) {
      return _fromProducts(
        strategyType: ResolvedPaywallStrategyType.saleEvent,
        segment: segment,
        products: event!.products,
        compactProducts: event.compactProducts,
        variant: variant,
        content: event.content,
        campaignId: event.campaignId,
        endAtUtc: event.endAtUtc,
        platform: params.platform,
      );
    }

    if (segment == ResolvedPaywallSegment.newUser && saleStrategy.newUser.enabled) {
      final impressionNumber = params.storedImpressionCount + 1;
      final rule = _matchedRule(saleStrategy.newUser.impressionRules, impressionNumber);
      if (rule == null) return _invalid('missing_new_user_rule', segment: segment, impressionNumber: impressionNumber);
      return _fromProducts(
        strategyType: ResolvedPaywallStrategyType.newUser,
        segment: segment,
        products: rule.products,
        compactProducts: rule.compactProducts,
        variant: variant,
        content: rule.content.copyWith(benefits: saleStrategy.newUser.content.benefits),
        impressionNumber: impressionNumber,
        ruleThreshold: rule.fromImpression,
        platform: params.platform,
      );
    }

    return _fromProducts(
      strategyType: ResolvedPaywallStrategyType.defaultUser,
      segment: segment,
      products: saleStrategy.defaultUser.products,
      compactProducts: saleStrategy.defaultUser.compactProducts,
      variant: variant,
      content: saleStrategy.defaultUser.content,
      platform: params.platform,
    );
  }

  ResolvedPaywallSegment _segmentFor(DateTime? installTime, DateTime nowUtc, int windowDays) {
    if (installTime == null || windowDays <= 0) return ResolvedPaywallSegment.defaultUser;
    final installDate = _dateOnly(installTime.toLocal());
    final nowDate = _dateOnly(nowUtc.toLocal());
    final ageDays = nowDate.difference(installDate).inDays;
    if (ageDays < 0 || ageDays >= windowDays) return ResolvedPaywallSegment.defaultUser;
    return ResolvedPaywallSegment.newUser;
  }

  DateTime _dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

  bool _isActiveEvent(PaywallSaleEventStrategyEntity? event, ResolvedPaywallSegment segment, DateTime nowUtc) {
    if (event == null || !event.enabled || event.startAtUtc == null || event.endAtUtc == null) return false;
    final audience = _audienceSegment(segment);
    if (!event.appliesTo.contains(audience)) return false;
    final now = nowUtc.toUtc();
    return !now.isBefore(event.startAtUtc!) && !now.isAfter(event.endAtUtc!);
  }

  PaywallAudienceSegment _audienceSegment(ResolvedPaywallSegment segment) {
    return switch (segment) {
      ResolvedPaywallSegment.defaultUser => PaywallAudienceSegment.defaultUser,
      ResolvedPaywallSegment.newUser => PaywallAudienceSegment.newUser,
    };
  }

  PaywallImpressionRuleEntity? _matchedRule(List<PaywallImpressionRuleEntity> rules, int impressionNumber) {
    final eligible = rules.where((rule) => rule.fromImpression > 0 && rule.fromImpression <= impressionNumber).toList()
      ..sort((a, b) => b.fromImpression.compareTo(a.fromImpression));
    return eligible.firstOrNull;
  }

  ResolvedPaywallStrategyEntity _fromProducts({
    required ResolvedPaywallStrategyType strategyType,
    required ResolvedPaywallSegment segment,
    required List<PaywallProductReferenceEntity> products,
    required List<PaywallProductReferenceEntity> compactProducts,
    required PaywallProductVariant variant,
    required PaywallContentEntity content,
    required PaymentPlatform platform,
    String campaignId = '',
    DateTime? endAtUtc,
    int? impressionNumber,
    int? ruleThreshold,
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
    if (!_hasValidProductIds(productIds)) {
      return _invalid(
        'invalid_product_ids',
        segment: segment,
        impressionNumber: impressionNumber,
        ruleThreshold: ruleThreshold,
      );
    }
    return ResolvedPaywallStrategyEntity(
      strategyType: strategyType,
      segment: segment,
      isValid: true,
      // Records the variant actually rendered, not the one asked for, so a
      // silent fallback to the full list is visible in tracking instead of
      // looking like a compact paywall that happened to show three plans.
      variant: usesCompact ? PaywallProductVariant.compact : PaywallProductVariant.full,
      campaignId: campaignId,
      endAtUtc: endAtUtc,
      impressionNumber: impressionNumber,
      ruleThreshold: ruleThreshold,
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

  ResolvedPaywallStrategyEntity _invalid(
    String reason, {
    ResolvedPaywallSegment segment = ResolvedPaywallSegment.defaultUser,
    int? impressionNumber,
    int? ruleThreshold,
  }) {
    return ResolvedPaywallStrategyEntity(
      strategyType: ResolvedPaywallStrategyType.invalid,
      segment: segment,
      impressionNumber: impressionNumber,
      ruleThreshold: ruleThreshold,
      invalidReason: reason,
    );
  }
}
