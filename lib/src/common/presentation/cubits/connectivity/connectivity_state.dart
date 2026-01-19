part of '../../../common.dart';

@freezed
abstract class ConnectivityState with _$ConnectivityState {
  const factory ConnectivityState({
    @Default(false) bool isLoading,
    @Default(true) bool isInternetConnected,
  }) = _ConnectivityState;

  factory ConnectivityState.initial() => const ConnectivityState();
}
