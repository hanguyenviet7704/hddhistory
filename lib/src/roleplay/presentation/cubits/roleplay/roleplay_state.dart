part of '../../../roleplay.dart';

enum RoleplayStatus { initial, loading, success, failure }

@freezed
abstract class RoleplayState with _$RoleplayState {
  const factory RoleplayState({
    @Default(RoleplayStatus.initial) RoleplayStatus status,
    @Default(LessonEntity()) LessonEntity currentLesson,
    @Default(LearningItemEntity()) LearningItemEntity currentLearningItem,
    @Default(RoleplayFeedbackEntity()) RoleplayFeedbackEntity feedback,
    @Default(false) bool isCurrentSectionRevealed,
    String? errorMessage,
  }) = _RoleplayState;

  factory RoleplayState.initial() => RoleplayState();

  factory RoleplayState.fromJson(Map<String, dynamic> json) => _$RoleplayStateFromJson(json);
}

extension RoleplayStateExtension on RoleplayState {
  RoleplayEntity get currentRoleplay {
    return currentLearningItem.roleplay;
  }
}
