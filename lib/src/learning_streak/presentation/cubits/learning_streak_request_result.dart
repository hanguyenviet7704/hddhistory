part of '../../learning_streak.dart';

enum LearningStreakRequestOutcome { success, failure, timeout, ignored }

@immutable
class LearningStreakRequestResult {
  const LearningStreakRequestResult({
    required this.requestId,
    required this.requestedUserId,
    required this.triggerSource,
    required this.outcome,
    required this.dataOrigin,
    required this.streak,
    this.errorMessage,
  });

  final String requestId;
  final String requestedUserId;
  final LearningStreakTriggerSource triggerSource;
  final LearningStreakRequestOutcome outcome;
  final LearningStreakDataOrigin dataOrigin;
  final UserLearningStreakEntity streak;
  final String? errorMessage;

  bool get isSuccess => outcome == LearningStreakRequestOutcome.success;
  bool get isFailure => outcome == LearningStreakRequestOutcome.failure;
  bool get isTimeout => outcome == LearningStreakRequestOutcome.timeout;
  bool get isIgnored => outcome == LearningStreakRequestOutcome.ignored;

  bool get isRemoteSuccessWithPositiveStreak {
    return isSuccess && dataOrigin == LearningStreakDataOrigin.remote && streak.currentStreak > 0;
  }
}
