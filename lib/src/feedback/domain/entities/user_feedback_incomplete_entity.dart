part of '../../feedback.dart';

@freezed
abstract class UserFeedbackIncompleteEntity with _$UserFeedbackIncompleteEntity {
  const factory UserFeedbackIncompleteEntity({
    @Default('') String courseId,
    @Default(BaseMultiLanguage()) BaseMultiLanguage courseTitle,
    @Default('') String lessonId,
    @Default(BaseMultiLanguage()) BaseMultiLanguage lessonTitle,
    @Default('') String keypointId,
    @Default(BaseMultiLanguage()) BaseMultiLanguage keypointTitle,
    @Default([]) List<IncompleteFeedbackReason> reasons,
    @Default('') String comment,
    DateTime? submittedAt,
  }) = _UserFeedbackIncompleteEntity;

  factory UserFeedbackIncompleteEntity.fromJson(Map<String, dynamic> json) => _$UserFeedbackIncompleteEntityFromJson(json);
}
