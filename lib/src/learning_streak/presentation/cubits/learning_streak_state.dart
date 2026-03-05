part of '../../learning_streak.dart';

enum LearningStreakStatus { initial, loading, success, failure }

enum LearningStreakTriggerSource { unknown, completionCta, homeChip }

@freezed
abstract class LearningStreakState with _$LearningStreakState {
  const factory LearningStreakState({
    @Default(LearningStreakStatus.initial) LearningStreakStatus status,
    @Default(UserLearningStreakEntity()) UserLearningStreakEntity selectedItem,
    String? errorMessage,
    @Default('') String requestId,
    @Default(LearningStreakTriggerSource.unknown) LearningStreakTriggerSource triggerSource,
    @Default('') String requestedUserId,
    @Default(LearningStreakDataOrigin.unknown) LearningStreakDataOrigin dataOrigin,
  }) = _LearningStreakState;

  factory LearningStreakState.initial() => LearningStreakState();

  factory LearningStreakState.fromJson(Map<String, dynamic> json) => _$LearningStreakStateFromJson(json);
}
