part of '../../feedback.dart';

@freezed
abstract class UserFeedbackIncompleteModel with _$UserFeedbackIncompleteModel {
  const factory UserFeedbackIncompleteModel({
    @Default('') String courseId,
    @Default(BaseMultiLanguage()) BaseMultiLanguage courseTitle,
    @Default('') String lessonId,
    @Default(BaseMultiLanguage()) BaseMultiLanguage lessonTitle,
    @Default('') String keypointId,
    @Default(BaseMultiLanguage()) BaseMultiLanguage keypointTitle,
    @Default([]) List<IncompleteFeedbackReason> reasons,
    @Default('') String comment,
    DateTime? submittedAt,
  }) = _UserFeedbackIncompleteModel;

  factory UserFeedbackIncompleteModel.fromJson(Map<String, dynamic> json) => _$UserFeedbackIncompleteModelFromJson(json);
}

enum IncompleteFeedbackReason {
  @JsonValue('hard_to_understand')
  hardToUnderstand,
  @JsonValue('not_engaging')
  notEngaging,
  @JsonValue('poor_visuals')
  poorVisuals,
  @JsonValue('hard_questions')
  hardQuestions,
  @JsonValue('needs_more_examples')
  needsMoreExamples,
}

extension IncompleteFeedbackReasonExtension on IncompleteFeedbackReason {
  String get apiValue {
    return switch (this) {
      IncompleteFeedbackReason.hardToUnderstand => 'hard_to_understand',
      IncompleteFeedbackReason.notEngaging => 'not_engaging',
      IncompleteFeedbackReason.poorVisuals => 'poor_visuals',
      IncompleteFeedbackReason.hardQuestions => 'hard_questions',
      IncompleteFeedbackReason.needsMoreExamples => 'needs_more_examples',
    };
  }
}

extension UserFeedbackIncompleteModelExtension on UserFeedbackIncompleteModel {
  UserFeedbackIncompleteEntity toEntity() => UserFeedbackIncompleteEntity(
    courseId: courseId,
    courseTitle: courseTitle,
    lessonId: lessonId,
    lessonTitle: lessonTitle,
    keypointId: keypointId,
    keypointTitle: keypointTitle,
    reasons: reasons,
    comment: comment,
    submittedAt: submittedAt,
  );
}
