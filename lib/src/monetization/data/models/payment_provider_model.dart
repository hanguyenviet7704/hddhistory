part of '../../monetization.dart';

@freezed
abstract class PaymentProviderModel with _$PaymentProviderModel {
  const factory PaymentProviderModel({
    @Default('') String id,
    @Default('') String providerName,
    @Default(false) bool isActive,
  }) = _PaymentProviderModel;

  factory PaymentProviderModel.fromJson(Map<String, dynamic> json) => _$PaymentProviderModelFromJson(json);
}

extension PaymentProviderModelExtension on PaymentProviderModel {
  PaymentProviderEntity toEntity() => PaymentProviderEntity(
    id: id,
    providerName: providerName,
    isActive: isActive,
  );
}