part of '../../../onboard.dart';

enum OnboardStatus { initial, loading, success, failure }

@freezed
abstract class OnboardState with _$OnboardState {
  const factory OnboardState({
    @Default(OnboardStatus.initial) OnboardStatus status,
    @Default(OnboardEntity()) OnboardEntity onboardData,
    OnboardEntity? selectedItem,
    UserEntity? userByDeviceId,
    String? errorMessage,
  }) = _OnboardState;

  factory OnboardState.initial() => OnboardState();

  factory OnboardState.fromJson(Map<String, dynamic> json) => _$OnboardStateFromJson(json);
}

extension OnboardStateExtension on OnboardState {
  List<OnboardMotivationEntity> get motivations => [
    onboardData.welcome,
    onboardData.motivationOne,
    onboardData.motivationTwo,
    onboardData.motivationThree,
  ];
}