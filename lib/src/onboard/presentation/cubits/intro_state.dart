part of '../../onboard.dart';

@freezed
sealed class IntroState with _$IntroState {
  const factory IntroState({
    @Default(0) int currentPage,
  }) = _IntroState;

  factory IntroState.initial() => const IntroState();
}
