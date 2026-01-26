part of '../../feedback.dart';

@freezed
abstract class UserFeedbackCompleteEntity with _$UserFeedbackCompleteEntity {
  const factory UserFeedbackCompleteEntity({
    @Default('') String courseId,
    @Default(BaseMultiLanguage()) BaseMultiLanguage courseTitle,
    @Default('') String lessonId,
    @Default(BaseMultiLanguage()) BaseMultiLanguage lessonTitle,
    @Default('') String keypointId,
    @Default(BaseMultiLanguage()) BaseMultiLanguage keypointTitle,
    @Default(0) int overallRating,
    @Default(0) int contentRating,
    @Default(0) int experienceRating,
    @Default('') String comment,
    DateTime? submittedAt,
  }) = _UserFeedbackCompleteEntity;

  factory UserFeedbackCompleteEntity.fromJson(Map<String, dynamic> json) => _$UserFeedbackCompleteEntityFromJson(json);
}
