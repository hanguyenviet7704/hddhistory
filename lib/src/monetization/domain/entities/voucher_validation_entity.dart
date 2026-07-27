part of '../../monetization.dart';

@freezed
abstract class VoucherProductMappingEntity with _$VoucherProductMappingEntity {
  const factory VoucherProductMappingEntity({
    @Default('') String baseProductId,
    @Default('') String targetProductId,
  }) = _VoucherProductMappingEntity;

  factory VoucherProductMappingEntity.fromJson(Map<String, dynamic> json) =>
      _$VoucherProductMappingEntityFromJson(json);
}

@freezed
abstract class VoucherValidationEntity with _$VoucherValidationEntity {
  const factory VoucherValidationEntity({
    @Default(false) bool valid,
    @Default(VoucherRejectReason.unknown) VoucherRejectReason reason,
    @Default('') String code,
    int? discountPercent,
    @Default(<VoucherProductMappingEntity>[]) List<VoucherProductMappingEntity> products,
  }) = _VoucherValidationEntity;

  factory VoucherValidationEntity.fromJson(Map<String, dynamic> json) =>
      _$VoucherValidationEntityFromJson(json);
}

extension VoucherValidationEntityX on VoucherValidationEntity {
  /// A code is only usable if the server said so AND it actually swaps at
  /// least one SKU — otherwise applying it would change nothing.
  bool get isUsable => valid && products.isNotEmpty;

  /// base SKU → discounted SKU, for rewriting the paywall's product list.
  Map<String, String> get swapMap => {
    for (final item in products) item.baseProductId: item.targetProductId,
  };
}
