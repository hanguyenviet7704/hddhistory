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
    @JsonKey(fromJson: _incompleteFeedbackReasonListFromJson, toJson: _incompleteFeedbackReasonListToJson) @Default([]) List<IncompleteFeedbackReason> reasons,
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
  @JsonValue('unknown')
  unknown
  ;

  static List<IncompleteFeedbackReason> get displayReasons => [
    hardToUnderstand,
    notEngaging,
    poorVisuals,
    hardQuestions,
    needsMoreExamples,
  ];

  static IncompleteFeedbackReason fromRawValue(String value) {
    return switch (value) {
      'hard_to_understand' => IncompleteFeedbackReason.hardToUnderstand,
      'not_engaging' => IncompleteFeedbackReason.notEngaging,
      'poor_visuals' => IncompleteFeedbackReason.poorVisuals,
      'hard_questions' => IncompleteFeedbackReason.hardQuestions,
      'needs_more_examples' => IncompleteFeedbackReason.needsMoreExamples,
      _ => IncompleteFeedbackReason.unknown,
    };
  }

  String get rawValue {
    return switch (this) {
      IncompleteFeedbackReason.hardToUnderstand => 'hard_to_understand',
      IncompleteFeedbackReason.notEngaging => 'not_engaging',
      IncompleteFeedbackReason.poorVisuals => 'poor_visuals',
      IncompleteFeedbackReason.hardQuestions => 'hard_questions',
      IncompleteFeedbackReason.needsMoreExamples => 'needs_more_examples',
      IncompleteFeedbackReason.unknown => 'unknown',
    };
  }

  String get apiValue {
    return rawValue;
  }

  String label(BuildContext context) {
    return switch (this) {
      IncompleteFeedbackReason.hardToUnderstand => context.l10n.feedback.reasonHardToUnderstand,
      IncompleteFeedbackReason.notEngaging => context.l10n.feedback.reasonNotEngaging,
      IncompleteFeedbackReason.poorVisuals => context.l10n.feedback.reasonPoorVisuals,
      IncompleteFeedbackReason.hardQuestions => context.l10n.feedback.reasonHardQuestions,
      IncompleteFeedbackReason.needsMoreExamples => context.l10n.feedback.reasonNeedsMoreExamples,
      IncompleteFeedbackReason.unknown => context.l10n.feedback.reasonHardToUnderstand,
    };
  }
}

extension IncompleteFeedbackReasonListExtension on List<IncompleteFeedbackReason> {
  static Map<IncompleteFeedbackReason, String> buildReasonLabels(BuildContext context) {
    return {
      IncompleteFeedbackReason.hardToUnderstand: context.l10n.feedback.reasonHardToUnderstand,
      IncompleteFeedbackReason.notEngaging: context.l10n.feedback.reasonNotEngaging,
      IncompleteFeedbackReason.poorVisuals: context.l10n.feedback.reasonPoorVisuals,
      IncompleteFeedbackReason.hardQuestions: context.l10n.feedback.reasonHardQuestions,
      IncompleteFeedbackReason.needsMoreExamples: context.l10n.feedback.reasonNeedsMoreExamples,
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

List<IncompleteFeedbackReason> _incompleteFeedbackReasonListFromJson(Object? rawValue) {
  if (rawValue is! List) return const [];

  return rawValue.map((item) {
    if (item is IncompleteFeedbackReason) return item;
    if (item is String) return IncompleteFeedbackReason.fromRawValue(item);
    return IncompleteFeedbackReason.unknown;
  }).toList();
}

List<String> _incompleteFeedbackReasonListToJson(List<IncompleteFeedbackReason> reasons) {
  return reasons.map((item) => item.rawValue).toList();
}
