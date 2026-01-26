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
