part of '../../monetization.dart';

/// One base SKU → discounted SKU swap the server authorised for this code.
@freezed
abstract class VoucherProductMappingModel with _$VoucherProductMappingModel {
  const factory VoucherProductMappingModel({
    @Default('') String baseProductId,
    @Default('') String targetProductId,
  }) = _VoucherProductMappingModel;

  factory VoucherProductMappingModel.fromJson(Map<String, dynamic> json) =>
      _$VoucherProductMappingModelFromJson(json);
}

/// Response of `POST /payment/vouchers/validate`.
///
/// The server — never the client — decides which SKUs a code unlocks, so that
/// a tampered build cannot force the deepest-discount product.
@freezed
abstract class VoucherValidationModel with _$VoucherValidationModel {
  const factory VoucherValidationModel({
    @Default(false) bool valid,
    @JsonKey(unknownEnumValue: VoucherRejectReason.unknown)
    @Default(VoucherRejectReason.unknown)
    VoucherRejectReason reason,
    @Default('') String code,
    int? discountPercent,
    @Default(<VoucherProductMappingModel>[]) List<VoucherProductMappingModel> products,
  }) = _VoucherValidationModel;

  factory VoucherValidationModel.fromJson(Map<String, dynamic> json) =>
      _$VoucherValidationModelFromJson(json);
}

/// Why the server refused a code. Values must stay in sync with the backend
/// (`payment/vouchers/validate`); each maps to its own localized message.
enum VoucherRejectReason {
  @JsonValue('not_found')
  notFound,
  @JsonValue('expired')
  expired,
  @JsonValue('exhausted')
  exhausted,
  @JsonValue('not_applicable')
  notApplicable,
  unknown,
}

extension VoucherValidationModelExtension on VoucherValidationModel {
  VoucherValidationEntity toEntity() => VoucherValidationEntity(
    valid: valid,
    reason: reason,
    code: code,
    discountPercent: discountPercent,
    products: products
        .where((item) => item.baseProductId.isNotEmpty && item.targetProductId.isNotEmpty)
        .map(
          (item) => VoucherProductMappingEntity(
            baseProductId: item.baseProductId,
            targetProductId: item.targetProductId,
          ),
        )
        .toList(),
  );
}
