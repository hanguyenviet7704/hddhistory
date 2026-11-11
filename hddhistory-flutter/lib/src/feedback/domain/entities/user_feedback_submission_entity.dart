part of '../../feedback.dart';

@freezed
abstract class UserFeedbackSubmissionEntity with _$UserFeedbackSubmissionEntity {
  const factory UserFeedbackSubmissionEntity({
    @Default('') String userId,
    @Default('') String courseId,
    @Default('') String lessonId,
    @Default('') String keypointId,
    @Default(FeedbackType.complete) FeedbackType type,
    @Default(FeedbackEntry.roleplay) FeedbackEntry entry,
    @Default(0) int overallRating,
    @Default(0) int contentRating,
    @Default(0) int experienceRating,
    @Default([]) List<IncompleteFeedbackReason> reasons,
    @Default('') String comment,
  }) = _UserFeedbackSubmissionEntity;
}
