part of '../../../home.dart';

@freezed
abstract class DeeplinkState with _$DeeplinkState {
  const factory DeeplinkState({
    @Default(false) bool isPassSplashScreen,
  }) = _DeeplinkState;

  factory DeeplinkState.initial() => const DeeplinkState();
}

