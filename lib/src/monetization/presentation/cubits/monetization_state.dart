part of '../../monetization.dart';

enum MonetizationStatus { initial, loading, success, failure }

@freezed
abstract class MonetizationState with _$MonetizationState {
  const factory MonetizationState({
    @Default(MonetizationStatus.initial) MonetizationStatus status,
    @Default(false) bool isAvailable,
    @Default([]) List<IapProductEntity> iapProducts,
    @Default('') String selectedProductId,
    String? errorMessage,
  }) = _MonetizationState;

  factory MonetizationState.initial() => MonetizationState();

  factory MonetizationState.fromJson(Map<String, dynamic> json) => _$MonetizationStateFromJson(json);
}
