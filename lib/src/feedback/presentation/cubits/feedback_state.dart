part of '../../feedback.dart';

enum FeedbackStatus { initial, loading, success, failure }

@freezed
abstract class FeedbackState with _$FeedbackState {
  const factory FeedbackState({
    @Default(FeedbackStatus.initial) FeedbackStatus status,
    @Default(UserFeedbackEntity()) UserFeedbackEntity userFeedback,
    String? errorMessage,
  }) = _FeedbackState;

  factory FeedbackState.initial() => FeedbackState();

  factory FeedbackState.fromJson(Map<String, dynamic> json) =>
      _$FeedbackStateFromJson(json);
}

