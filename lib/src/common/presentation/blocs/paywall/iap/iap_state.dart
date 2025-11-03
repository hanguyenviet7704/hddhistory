part of '../../blocs.dart';

@freezed
abstract class IAPState with _$IAPState {
  const factory IAPState({
    @Default(false) bool isAvailable,
    @Default(false) bool isLoading,
    @Default([]) List<IapProduct> iapProducts,
    @Default('') String selectedProductId,
    
    @Default(null) String? error,
  }) = _IAPState;

  factory IAPState.initial() => const IAPState();
}
