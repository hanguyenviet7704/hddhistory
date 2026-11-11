part of '../../spaced_review.dart';

abstract class ISpacedReviewRepository {
  TaskEither<AppException, SpacedReviewTodayEntity> getToday();

  TaskEither<AppException, Unit> submitAnswers(List<SpacedReviewResultEntity> results);
}
