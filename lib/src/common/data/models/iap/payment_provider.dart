part of '../models.dart';

@freezed
abstract class PaymentProvider with _$PaymentProvider {
  const factory PaymentProvider({
    @Default('') String id,
    @Default('') String providerName,
    @Default(false) bool isActive,
  }) = _PaymentProvider;

  factory PaymentProvider.fromJson(Map<String, dynamic> json) => _$PaymentProviderFromJson(json);
}