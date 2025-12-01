part of '../models.dart';

@freezed
abstract class ActiveProduct with _$ActiveProduct {
  const factory ActiveProduct({
    required String id,
    @Default('') String profileId,
    // @Default(IapProduct()) IapProduct subscriptionPlan,
    @Default('') String status,
  }) = _ActiveProduct;

  factory ActiveProduct.fromJson(Map<String, dynamic> json) => _$ActiveProductFromJson(json);
}