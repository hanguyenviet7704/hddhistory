part of '../../monetization.dart';

/// Which paywall body THIS viewer was assigned, and whether the assignment
/// counts towards the A/B run.
///
/// [inExperiment] false means "render [variant], but do not report an arm" —
/// the server excludes viewers it cannot keep in a stable arm (no id) or whose
/// locale has no comparison rows of its own, and reporting them would put a
/// third treatment inside one of the two arms. An empty [key] means no run is
/// configured at all.
@freezed
abstract class PaywallBodyExperimentEntity with _$PaywallBodyExperimentEntity {
  const factory PaywallBodyExperimentEntity({
    @Default('') String key,
    @Default(PaywallBodyVariant.benefits) PaywallBodyVariant variant,
    @Default(false) bool inExperiment,
  }) = _PaywallBodyExperimentEntity;

  factory PaywallBodyExperimentEntity.fromJson(Map<String, dynamic> json) =>
      _$PaywallBodyExperimentEntityFromJson(json);
}

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

    /// The body A/B assignment carried by the same response. Present even when
    /// [active] is false — most of the time no campaign is running, and the
    /// experiment still has to be resolved for that viewer.
    @Default(PaywallBodyExperimentEntity()) PaywallBodyExperimentEntity experiment,
  }) = _PaywallLogicSaleEntity;

  factory PaywallLogicSaleEntity.fromJson(Map<String, dynamic> json) => _$PaywallLogicSaleEntityFromJson(json);
}
