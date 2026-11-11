part of '../../spaced_review.dart';

@freezed
abstract class SpacedReviewTodayEntity with _$SpacedReviewTodayEntity {
  const factory SpacedReviewTodayEntity({
    @Default(0) int dueCount,
    @Default([]) List<SpacedReviewKeypointEntity> keypoints,
    DateTime? nextDueAt,
  }) = _SpacedReviewTodayEntity;
}

@freezed
abstract class SpacedReviewKeypointEntity with _$SpacedReviewKeypointEntity {
  const factory SpacedReviewKeypointEntity({
    @Default('') String keypointId,
    @Default('') String lessonId,
    @Default('') String courseId,
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @Default([]) List<QuestionEntity> questions,
  }) = _SpacedReviewKeypointEntity;
}

/// One keypoint's outcome for the session: correct only if every question of
/// that keypoint was answered correctly.
@freezed
abstract class SpacedReviewResultEntity with _$SpacedReviewResultEntity {
  const factory SpacedReviewResultEntity({
    required String keypointId,
    required bool correct,
  }) = _SpacedReviewResultEntity;
}
