part of '../../feedback.dart';

@freezed
abstract class UserFeedbackCompleteModel with _$UserFeedbackCompleteModel {
  const factory UserFeedbackCompleteModel({
    @Default('') String courseId,
    @Default(BaseMultiLanguage()) BaseMultiLanguage courseTitle,
    @Default('') String lessonId,
    @Default(BaseMultiLanguage()) BaseMultiLanguage lessonTitle,
    @Default('') String keypointId,
    @Default(BaseMultiLanguage()) BaseMultiLanguage keypointTitle,
    @Default(0) int contentRating,
    @Default(0) int experienceRating,
    @Default('') String comment,
    DateTime? submittedAt,
  }) = _UserFeedbackCompleteModel;

  factory UserFeedbackCompleteModel.fromJson(Map<String, dynamic> json) =>
      _$UserFeedbackCompleteModelFromJson(json);
}

extension UserFeedbackCompleteModelExtension on UserFeedbackCompleteModel {
  UserFeedbackCompleteEntity toEntity() => UserFeedbackCompleteEntity(
        courseId: courseId,
        courseTitle: courseTitle,
        lessonId: lessonId,
        lessonTitle: lessonTitle,
        keypointId: keypointId,
        keypointTitle: keypointTitle,
        contentRating: contentRating,
        experienceRating: experienceRating,
        comment: comment,
        submittedAt: submittedAt,
      );
}
