
part of '../../achievenment.dart';

enum AchievenmentStatus { initial, loading, success, failure }

@freezed
abstract class AchievenmentState with _$AchievenmentState {
  const factory AchievenmentState({
    @Default(AchievenmentStatus.initial) AchievenmentStatus status,
    AchievenmentResponseEntity? selectedItem,
    String? errorMessage,
  }) = _AchievenmentState;

  factory AchievenmentState.initial() => AchievenmentState();

  factory AchievenmentState.fromJson(Map<String, dynamic> json) => _$AchievenmentStateFromJson(json);
}

