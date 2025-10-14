part of '../../onboard.dart';

enum OnboardStatus { initial, loading, success, failure }

@freezed
abstract class OnboardState with _$OnboardState {
  const factory OnboardState({
    @Default(OnboardStatus.initial) OnboardStatus status,
    @Default([]) List<OnboardEntity> items,
    OnboardEntity? selectedItem,
    String? errorMessage,
  }) = _OnboardState;

  factory OnboardState.initial() => const OnboardState();

  factory OnboardState.fromJson(Map<String, dynamic> json) => _$OnboardStateFromJson(json);
}
