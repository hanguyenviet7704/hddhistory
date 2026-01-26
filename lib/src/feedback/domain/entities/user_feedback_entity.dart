part of '../../feedback.dart';

@freezed
abstract class UserFeedbackEntity with _$UserFeedbackEntity {
  const factory UserFeedbackEntity({
    @Default('') String userId,
    @Default(UserFeedbackCompleteEntity()) UserFeedbackCompleteEntity roleplayComplete,
    @Default(UserFeedbackIncompleteEntity()) UserFeedbackIncompleteEntity roleplayIncomplete,
    @Default(UserFeedbackCompleteEntity()) UserFeedbackCompleteEntity keypointComplete,
    @Default(UserFeedbackIncompleteEntity()) UserFeedbackIncompleteEntity keypointIncomplete,
  }) = _UserFeedbackEntity;

  factory UserFeedbackEntity.fromJson(Map<String, dynamic> json) => _$UserFeedbackEntityFromJson(json);
}

extension UserFeedbackEntityExtension on UserFeedbackEntity {
  bool get userHasRoleplayFeedbackComplete => roleplayComplete.courseId.isNotEmpty;
  bool get userHasRoleplayFeedbackIncomplete => roleplayIncomplete.courseId.isNotEmpty;
  bool get userHasKeypointFeedbackComplete => keypointComplete.courseId.isNotEmpty;
  bool get userHasKeypointFeedbackIncomplete => keypointIncomplete.courseId.isNotEmpty;
}