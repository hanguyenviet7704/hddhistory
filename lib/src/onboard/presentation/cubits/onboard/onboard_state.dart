part of '../../../onboard.dart';

enum OnboardStatus { initial, loading, success, failure }

enum OnboardDeviceCheckStatus { initial, loading, success, failure }

@freezed
abstract class OnboardState with _$OnboardState {
  const factory OnboardState({
    @Default(OnboardStatus.initial) OnboardStatus status,
    @Default(OnboardDeviceCheckStatus.initial) OnboardDeviceCheckStatus deviceCheckStatus,
    @Default(OnboardEntity()) OnboardEntity onboardData,
    OnboardEntity? selectedItem,
    @Default(UserEntity()) UserEntity userByDeviceId,
    String? errorMessage,
    String? deviceCheckErrorMessage,
  }) = _OnboardState;

  factory OnboardState.initial() => OnboardState();

  factory OnboardState.fromJson(Map<String, dynamic> json) => _$OnboardStateFromJson(json);
}

extension OnboardStateExtension on OnboardState {
  bool get hasRecognizedDevice => userByDeviceId.id.isNotEmpty;
  bool get shouldContinueOnboarding => deviceCheckStatus != OnboardDeviceCheckStatus.loading && !hasRecognizedDevice;

  List<OnboardMotivationEntity> get motivations => [
    onboardData.welcome,
    onboardData.motivationOne,
    onboardData.motivationTwo,
    onboardData.motivationThree,
  ];
}
