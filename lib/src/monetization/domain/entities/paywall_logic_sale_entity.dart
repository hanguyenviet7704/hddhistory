part of '../../monetization.dart';

/// The "LogicSale" campaign — a per-user, segment-targeted limited-time offer
/// resolved server-side (`GET /paywall-config/logic-sale`), independent of the
/// CMS-authored `saleStrategy.saleEvent` [ResolvePaywallStrategyUsecase]
/// already resolves. Additive and background: a failed fetch or `active:
/// false` simply means "nothing to layer on top", never a blocked paywall —
/// see IapCubit._resolveLogicSale.
@freezed
abstract class PaywallLogicSaleEntity with _$PaywallLogicSaleEntity {
  const factory PaywallLogicSaleEntity({
    @Default(false) bool active,
    @Default('') String id,
    @Default('') String name,

    /// The SKU list this campaign wants the FULL paywall to offer instead of
    /// the resolved strategy's own list. Never applied to the compact 33%-off
    /// sheet — same rule as `saleStrategy.saleEvent`.
    @Default(<PaywallProductReferenceEntity>[]) List<PaywallProductReferenceEntity> products,

    /// Whether the full paywall should render a countdown strip toward
    /// [endAtUtc]. Independent of whether [products] actually resolved to a
    /// usable override — see IapCubit._logicSaleLocalDeadline.
    @Default(false) bool countdown,
    DateTime? startAtUtc,
    DateTime? endAtUtc,

    /// The server's own clock at the moment it answered — the anchor
    /// [endAtUtc] is measured against, so the client never has to trust its
    /// own wall clock for the absolute deadline.
    DateTime? nowUtc,
  }) = _PaywallLogicSaleEntity;

  factory PaywallLogicSaleEntity.fromJson(Map<String, dynamic> json) => _$PaywallLogicSaleEntityFromJson(json);
}
