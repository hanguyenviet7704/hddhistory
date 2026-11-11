part of '../../monetization.dart';

/// One SKU reference inside a `logic-sale` response — same shape as
/// [PaywallProductReferenceEntity], kept as its own model so this file stays
/// a plain wire-format mirror of `GET /paywall-config/logic-sale` and the
/// mapping to the domain type is explicit in [PaywallLogicSaleModelExtension].
@freezed
abstract class PaywallLogicSaleProductModel with _$PaywallLogicSaleProductModel {
  const factory PaywallLogicSaleProductModel({
    @Default('') String appleProductId,
    @Default('') String googleProductId,
  }) = _PaywallLogicSaleProductModel;

  factory PaywallLogicSaleProductModel.fromJson(Map<String, dynamic> json) =>
      _$PaywallLogicSaleProductModelFromJson(json);
}

/// The body A/B assignment the same response carries.
///
/// Rides on the logic-sale call rather than a request of its own: that call is
/// already made when the paywall opens, is per-viewer and uncached, and its
/// answer is already threaded into the purchase verify — the exact rail the
/// assignment needs. See `PaywallConfigService.assignBodyVariant`.
@freezed
abstract class PaywallBodyExperimentModel with _$PaywallBodyExperimentModel {
  const factory PaywallBodyExperimentModel({
    @Default('') String key,
    @Default('') String variant,
    @Default(false) bool inExperiment,
  }) = _PaywallBodyExperimentModel;

  factory PaywallBodyExperimentModel.fromJson(Map<String, dynamic> json) =>
      _$PaywallBodyExperimentModelFromJson(json);
}

/// Response of `GET /paywall-config/logic-sale`.
@freezed
abstract class PaywallLogicSaleModel with _$PaywallLogicSaleModel {
  const factory PaywallLogicSaleModel({
    @Default(false) bool active,
    DateTime? nowUtc,
    @Default('') String id,
    @Default('') String name,
    @Default(<PaywallLogicSaleProductModel>[]) List<PaywallLogicSaleProductModel> products,
    @Default(false) bool countdown,
    DateTime? startAtUtc,
    DateTime? endAtUtc,
    PaywallBodyExperimentModel? experiment,
  }) = _PaywallLogicSaleModel;

  factory PaywallLogicSaleModel.fromJson(Map<String, dynamic> json) => _$PaywallLogicSaleModelFromJson(json);
}

extension PaywallLogicSaleModelExtension on PaywallLogicSaleModel {
  PaywallLogicSaleEntity toEntity() => PaywallLogicSaleEntity(
    active: active,
    id: id,
    name: name,
    products: products
        .map(
          (item) => PaywallProductReferenceEntity(
            appleProductId: item.appleProductId,
            googleProductId: item.googleProductId,
          ),
        )
        .toList(),
    countdown: countdown,
    startAtUtc: startAtUtc,
    endAtUtc: endAtUtc,
    nowUtc: nowUtc,
    experiment: PaywallBodyExperimentEntity(
      key: experiment?.key ?? '',
      // Unknown strings (a server that learns a third body before this build
      // does) land on benefits: the arm we cannot render is not an arm we may
      // silently report having shown.
      variant: experiment?.variant == 'comparison' ? PaywallBodyVariant.comparison : PaywallBodyVariant.benefits,
      inExperiment: experiment?.inExperiment ?? false,
    ),
  );
}
