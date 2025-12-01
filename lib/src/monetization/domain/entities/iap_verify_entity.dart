part of '../../monetization.dart';

@freezed
abstract class IapVerifyEntity with _$IapVerifyEntity {
  const factory IapVerifyEntity({
    @JsonKey(name: 'productId') @Default('') String productId,
    @JsonKey(name: 'orderId') @Default('') String orderId,
    @JsonKey(name: 'transactionId') @Default('') String transactionId,
    @JsonKey(name: 'expiryDate') @Default(null) DateTime? expiryDate,
    @Default('') String status,
    @Default('') String message,
  }) = _IapVerifyEntity;

  factory IapVerifyEntity.fromJson(Map<String, dynamic> json) => _$IapVerifyEntityFromJson(json);
}
