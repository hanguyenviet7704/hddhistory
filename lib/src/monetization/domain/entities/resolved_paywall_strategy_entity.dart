part of '../../monetization.dart';

@freezed
abstract class ResolvedPaywallStrategyEntity with _$ResolvedPaywallStrategyEntity {
  const ResolvedPaywallStrategyEntity._();

  const factory ResolvedPaywallStrategyEntity({
    @Default(ResolvedPaywallStrategyType.invalid) ResolvedPaywallStrategyType strategyType,
    @Default(ResolvedPaywallSegment.defaultUser) ResolvedPaywallSegment segment,
    @Default(false) bool isValid,
    @Default('') String campaignId,
    DateTime? endAtUtc,
    int? impressionNumber,
    int? ruleThreshold,
    @Default([]) List<String> productIds,
    @Default(PaywallContentEntity()) PaywallContentEntity content,
    @Default('') String invalidReason,
  }) = _ResolvedPaywallStrategyEntity;

  factory ResolvedPaywallStrategyEntity.fromJson(Map<String, dynamic> json) => _$ResolvedPaywallStrategyEntityFromJson(json);

  String get signature {
    return [
      strategyType.name,
      segment.name,
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
