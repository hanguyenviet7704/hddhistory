part of '../../feedback.dart';

enum FeedbackStatus { initial, loading, success, failure }

@freezed
abstract class FeedbackState with _$FeedbackState {
  const factory FeedbackState({
    @Default(FeedbackStatus.initial) FeedbackStatus status,
    @Default(UserFeedbackEntity()) UserFeedbackEntity userFeedback,
    @Default(FeedbackType.complete) FeedbackType activeType,
    @Default(FeedbackEntry.roleplay) FeedbackEntry activeEntry,
    @Default(0) int draftContentRating,
    @Default(0) int draftExperienceRating,
    @Default([]) List<IncompleteFeedbackReason> draftReasons,
    @Default('') String draftComment,
    String? errorMessage,
  }) = _FeedbackState;

  factory FeedbackState.initial() => FeedbackState();

  factory FeedbackState.fromJson(Map<String, dynamic> json) => _$FeedbackStateFromJson(json);
}
