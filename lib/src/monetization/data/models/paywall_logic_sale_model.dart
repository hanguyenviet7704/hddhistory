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
  );
}
