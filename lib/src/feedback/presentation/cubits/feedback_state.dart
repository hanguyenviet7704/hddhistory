part of '../../feedback.dart';

enum FeedbackStatus { initial, loading, success, failure }

@freezed
abstract class FeedbackState with _$FeedbackState {
  const factory FeedbackState({
    @Default(FeedbackStatus.initial) FeedbackStatus status,
    @Default(UserFeedbackEntity()) UserFeedbackEntity userFeedback,
    @Default(FeedbackType.complete) FeedbackType activeType,
    @Default(FeedbackEntry.roleplay) FeedbackEntry activeEntry,
    @Default('') String activeCourseId,
    @Default('') String activeLessonId,
    @Default('') String activeKeypointId,
    FeedbackEntry? pendingFeedbackIncompletePrompt,
    @Default(0) int draftOverallRating,
    @Default(0) int draftContentRating,
    @Default(0) int draftExperienceRating,
    @Default([]) List<IncompleteFeedbackReason> draftReasons,
    @Default('') String draftComment,
    String? errorMessage,
  }) = _FeedbackState;

  factory FeedbackState.initial() => FeedbackState();

  factory FeedbackState.fromJson(Map<String, dynamic> json) => _$FeedbackStateFromJson(json);
}

extension FeedbackStateExtension on FeedbackState {
  bool get isLoading {
    return status == FeedbackStatus.loading;
  }

  bool get feedbackCompleteCanSubmit {
    return draftOverallRating > 0 && draftContentRating > 0 && draftExperienceRating > 0 && draftComment.isNotEmpty && !isLoading;
  }

  bool get feedbackIncompleteCanSubmit {
    return (draftReasons.isNotEmpty || draftComment.trim().isNotEmpty) && !isLoading;
  }

  String get pageRouteName {
    if (activeType == FeedbackType.incomplete) return RouteNamed.courseRoadmap;
    if (activeEntry == FeedbackEntry.roleplay) return RouteNamed.roleplayFeedback;
    return RouteNamed.keypointComplete;
  }
}
