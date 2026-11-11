part of '../../spaced_review.dart';

@freezed
abstract class SpacedReviewTodayModel with _$SpacedReviewTodayModel {
  const factory SpacedReviewTodayModel({
    @Default(0) int dueCount,
    @Default([]) List<SpacedReviewKeypointModel> keypoints,
    DateTime? nextDueAt,
  }) = _SpacedReviewTodayModel;

  factory SpacedReviewTodayModel.fromJson(Map<String, dynamic> json) => _$SpacedReviewTodayModelFromJson(json);
}

@freezed
abstract class SpacedReviewKeypointModel with _$SpacedReviewKeypointModel {
  const factory SpacedReviewKeypointModel({
    @Default('') String keypointId,
    @Default('') String lessonId,
    @Default('') String courseId,
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    // Server reuses the daily-warm-up exercise shape for questions.
    @Default([]) List<QuestionModel> questions,
  }) = _SpacedReviewKeypointModel;

  factory SpacedReviewKeypointModel.fromJson(Map<String, dynamic> json) => _$SpacedReviewKeypointModelFromJson(json);
}

extension SpacedReviewTodayModelX on SpacedReviewTodayModel {
  SpacedReviewTodayEntity toEntity() => SpacedReviewTodayEntity(
    dueCount: dueCount,
    keypoints: keypoints.map((keypoint) => keypoint.toEntity()).toList(),
    nextDueAt: nextDueAt?.toLocal(),
  );
}

extension SpacedReviewKeypointModelX on SpacedReviewKeypointModel {
  SpacedReviewKeypointEntity toEntity() => SpacedReviewKeypointEntity(
    keypointId: keypointId,
    lessonId: lessonId,
    courseId: courseId,
    title: title,
    questions: questions.map((question) => question.toEntity()).toList(),
  );
}
