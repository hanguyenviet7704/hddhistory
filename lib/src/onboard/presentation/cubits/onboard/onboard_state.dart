part of '../../../onboard.dart';

enum OnboardStatus { initial, loading, success, failure }

@freezed
abstract class OnboardState with _$OnboardState {
  const factory OnboardState({
    @Default(OnboardStatus.initial) OnboardStatus status,
    @Default(OnboardEntity()) OnboardEntity onboardData,
    OnboardEntity? selectedItem,
    String? errorMessage,
  }) = _OnboardState;

  factory OnboardState.initial() => OnboardState();

  factory OnboardState.fromJson(Map<String, dynamic> json) => _$OnboardStateFromJson(json);
}
