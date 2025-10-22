part of '../models.dart';

@freezed
abstract class IapVerify with _$IapVerify {
  const factory IapVerify({
    @JsonKey(name: 'productId') @Default('') String productId,
    @JsonKey(name: 'orderId') @Default('') String orderId,
    @JsonKey(name: 'transactionId') @Default('') String transactionId,
    @JsonKey(name: 'expiryDate') @Default(null) DateTime? expiryDate,
    @Default('') String status,
    @Default('') String message,
  }) = _IapVerify;

  factory IapVerify.fromJson(Map<String, dynamic> json) => _$IapVerifyFromJson(json);
}
