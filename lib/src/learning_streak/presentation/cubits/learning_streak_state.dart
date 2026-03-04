
part of '../../learning_streak.dart';

enum LearningStreakStatus { initial, loading, success, failure }

@freezed
abstract class LearningStreakState with _$LearningStreakState {
  const factory LearningStreakState({
    @Default(LearningStreakStatus.initial) LearningStreakStatus status,
    UserLearningStreakEntity? selectedItem,
    String? errorMessage,
  }) = _LearningStreakState;

  factory LearningStreakState.initial() => LearningStreakState();

  factory LearningStreakState.fromJson(Map<String, dynamic> json) => _$LearningStreakStateFromJson(json);
}

