part of '../../monetization.dart';

@freezed
abstract class ResolvedPaywallStrategyEntity with _$ResolvedPaywallStrategyEntity {
  const ResolvedPaywallStrategyEntity._();

  const factory ResolvedPaywallStrategyEntity({
    @Default(ResolvedPaywallStrategyType.invalid) ResolvedPaywallStrategyType strategyType,
    @Default(ResolvedPaywallSegment.defaultUser) ResolvedPaywallSegment segment,
    @Default(false) bool isValid,

    /// The SKU-list variant actually rendered — after any fallback from an
    /// unusable compact list to the full one.
    @Default(PaywallProductVariant.full) PaywallProductVariant variant,
    @Default('') String campaignId,
    DateTime? endAtUtc,
    int? impressionNumber,
    int? ruleThreshold,
    @Default([]) List<String> productIds,
    @Default(PaywallContentEntity()) PaywallContentEntity content,
    @Default('') String invalidReason,
  }) = _ResolvedPaywallStrategyEntity;

  factory ResolvedPaywallStrategyEntity.fromJson(Map<String, dynamic> json) => _$ResolvedPaywallStrategyEntityFromJson(json);

  /// Identity of "the paywall this resolves to", used by
  /// [IapCubit.loadIapProducts] to decide whether the already-loaded store
  /// products can be reused.
  ///
  /// [variant] belongs here even though [productIds] already differs between
  /// variants: leaving it out made the two indistinguishable whenever a compact
  /// list fell back to the full one, and reasoning about a cache key is easier
  /// when every input that chose the products is in it.
  String get signature {
    return [
      strategyType.name,
      segment.name,
      variant.name,
      campaignId,
      impressionNumber?.toString() ?? '',
      ruleThreshold?.toString() ?? '',
      productIds.join(','),
    ].join('|');
  }

  bool get hasSaleCountdown => strategyType == ResolvedPaywallStrategyType.saleEvent && endAtUtc != null;
}

enum ResolvedPaywallStrategyType {
  @JsonValue('invalid')
  invalid,
  @JsonValue('defaultUser')
  defaultUser,
  @JsonValue('newUser')
  newUser,
  @JsonValue('saleEvent')
  saleEvent,
}

enum ResolvedPaywallSegment {
  @JsonValue('defaultUser')
  defaultUser,
  @JsonValue('newUser')
  newUser,
}
