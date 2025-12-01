part of '../../monetization.dart';

@freezed
abstract class PaymentProviderEntity with _$PaymentProviderEntity {
  const factory PaymentProviderEntity({
    @Default('') String id,
    @Default('') String providerName,
    @Default(false) bool isActive,
  }) = _PaymentProviderEntity;

  factory PaymentProviderEntity.fromJson(Map<String, dynamic> json) => _$PaymentProviderEntityFromJson(json);
}
