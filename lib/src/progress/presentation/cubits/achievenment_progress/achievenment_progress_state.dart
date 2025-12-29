part of '../../../progress.dart';

enum AchievenmentProgressStatus { initial, loading, success, failure }

@freezed
abstract class AchievenmentProgressState with _$AchievenmentProgressState {
  const factory AchievenmentProgressState({
    @Default(AchievenmentProgressStatus.initial) AchievenmentProgressStatus status,
    @Default([]) List<AchievenmentResponseEntity> achievenmentResponses,
    @Default([]) List<CourseLevelProgressEntity> courseLevelProgresses,
    String? errorMessage,
  }) = _AchievenmentProgressState;

  factory AchievenmentProgressState.initial() => AchievenmentProgressState();

  factory AchievenmentProgressState.fromJson(Map<String, dynamic> json) => _$AchievenmentProgressStateFromJson(json);
}
