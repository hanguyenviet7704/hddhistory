part of '../../../roleplay.dart';

enum RoleplayStatus { initial, loading, success, failure }

@freezed
abstract class RoleplayState with _$RoleplayState {
  const factory RoleplayState({
    @Default(RoleplayStatus.initial) RoleplayStatus status,
    @Default(LearningItemEntity()) LearningItemEntity currentLearningItem,
    @Default(0) int currentSectionIndex,
    @Default(false) bool isCurrentSectionRevealed,
    RoleplayFeedbackEntity? feedback,
    String? errorMessage,
  }) = _RoleplayState;

  factory RoleplayState.initial() => RoleplayState();

  factory RoleplayState.fromJson(Map<String, dynamic> json) => _$RoleplayStateFromJson(json);
}

extension RoleplayStateExtension on RoleplayState {
  SectionEntity get currentSection {
    return currentLearningItem.sections.elementAtOrDefault(currentSectionIndex, defaultValue: SectionEntity());
  }
}
