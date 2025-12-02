part of '../../../monetization.dart';

enum PaywallStatus { initial, loading, success, failure }

@freezed
abstract class PaywallState with _$PaywallState {
  const factory PaywallState({
    @Default(PaywallStatus.initial) PaywallStatus status,
    @Default(false) bool isShowAllPlans,
    @Default(false) bool isShowPurchaseSuccess,
  }) = _PaywallState;

  factory PaywallState.initial() => PaywallState();

  factory PaywallState.fromJson(Map<String, dynamic> json) => _$PaywallStateFromJson(json);
}
