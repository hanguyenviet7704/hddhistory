part of '../../monetization.dart';

class ResolvePaywallStrategyParams {
  final PaywallConfigEntity config;
  final PaymentPlatform platform;
  final DateTime nowUtc;
  final DateTime? installTime;
  final int storedImpressionCount;

  const ResolvePaywallStrategyParams({
    required this.config,
    required this.platform,
    required this.nowUtc,
    required this.installTime,
    required this.storedImpressionCount,
  });
}

@lazySingleton
class ResolvePaywallStrategyUsecase {
  const ResolvePaywallStrategyUsecase();

  ResolvedPaywallStrategyEntity call(ResolvePaywallStrategyParams params) {
    final saleStrategy = params.config.saleStrategy;
    if (saleStrategy == null) return _invalid('missing_sale_strategy');

    final segment = _segmentFor(params.installTime, params.nowUtc, saleStrategy.newUser.windowDays);
    final event = saleStrategy.saleEvent;
    if (_isActiveEvent(event, segment, params.nowUtc)) {
      return _fromProducts(
        strategyType: ResolvedPaywallStrategyType.saleEvent,
        segment: segment,
        products: event!.products,
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
    required PaywallContentEntity content,
    required PaymentPlatform platform,
    String campaignId = '',
    DateTime? endAtUtc,
    int? impressionNumber,
    int? ruleThreshold,
  }) {
    final productIds = _platformProductIds(products, platform);
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
