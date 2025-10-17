part of '../../onboard.dart';

enum OnboardStatus { initial, loading, success, failure }

@freezed
abstract class OnboardState with _$OnboardState {
  const factory OnboardState({
    @Default(OnboardStatus.initial) OnboardStatus status,
    @Default(BasePageBreak<OnboardEntity>()) BasePageBreak<OnboardEntity> pageData,
    OnboardEntity? selectedItem,
    String? errorMessage,
  }) = _OnboardState;

  factory OnboardState.initial() => OnboardState();

  factory OnboardState.fromJson(Map<String, dynamic> json) => _$OnboardStateFromJson(json);
}
