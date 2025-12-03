part of '../../../monetization.dart';

enum MonetizationStatus { initial, loading, success, failure }

@freezed
abstract class IapState with _$IapState {
  const factory IapState({
    @Default(MonetizationStatus.initial) MonetizationStatus status,
    @Default(false) bool isAvailable,
    @Default([]) List<IapProductEntity> iapProducts,
    @Default('') String selectedProductId,
    String? errorMessage,
  }) = _IapState;

  factory IapState.initial() => IapState();

  factory IapState.fromJson(Map<String, dynamic> json) => _$IapStateFromJson(json);
}

extension IapStateX on IapState {
  IapProductEntity get bestDealProduct => iapProducts.firstWhere((element) => element.bestDeal);
}