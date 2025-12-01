part of '../../monetization.dart';

@freezed
abstract class IapVerifyModel with _$IapVerifyModel {
  const factory IapVerifyModel({
    @JsonKey(name: 'productId') @Default('') String productId,
    @JsonKey(name: 'orderId') @Default('') String orderId,
    @JsonKey(name: 'transactionId') @Default('') String transactionId,
    @JsonKey(name: 'expiryDate') @Default(null) DateTime? expiryDate,
    @Default('') String status,
    @Default('') String message,
  }) = _IapVerifyModel;

  factory IapVerifyModel.fromJson(Map<String, dynamic> json) => _$IapVerifyModelFromJson(json);
}

extension IapVerifyModelExtension on IapVerifyModel {
  IapVerifyEntity toEntity() => IapVerifyEntity(
    productId: productId,
    orderId: orderId,
    transactionId: transactionId,
    expiryDate: expiryDate,
    status: status,
    message: message,
  );
}