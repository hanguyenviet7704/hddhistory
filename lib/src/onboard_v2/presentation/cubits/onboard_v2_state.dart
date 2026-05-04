
part of '../../onboard_v2.dart';

enum OnboardV2Status { initial, loading, success, failure }

@freezed
abstract class OnboardV2State with _$OnboardV2State {
  const factory OnboardV2State({
    @Default(OnboardV2Status.initial) OnboardV2Status status,
    @Default(BasePageBreak<OnboardV2Entity>()) BasePageBreak<OnboardV2Entity> pageData,
    OnboardV2Entity? selectedItem,
    String? errorMessage,
  }) = _OnboardV2State;

  factory OnboardV2State.initial() => OnboardV2State();

  factory OnboardV2State.fromJson(Map<String, dynamic> json) => _$OnboardV2StateFromJson(json);
}

