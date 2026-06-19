part of '../../lesson.dart';

/// Reasons a learner can pick when reporting an issue with a lesson.
/// [apiValue] matches the backend `IssueReportReason` enum.
enum IssueReportReason {
  inaccurateContent,
  differentFromPreview,
  confusingExplanation,
  translationError,
  hardToRead;

  String get apiValue => switch (this) {
    IssueReportReason.inaccurateContent => 'INACCURATE_CONTENT',
    IssueReportReason.differentFromPreview => 'DIFFERENT_FROM_PREVIEW',
    IssueReportReason.confusingExplanation => 'CONFUSING_EXPLANATION',
    IssueReportReason.translationError => 'TRANSLATION_ERROR',
    IssueReportReason.hardToRead => 'HARD_TO_READ',
  };

  // TODO(l10n): move to the localization pipeline (Google Sheets) when keys are added.
  String get label => switch (this) {
    IssueReportReason.inaccurateContent => 'Inaccurate content',
    IssueReportReason.differentFromPreview => 'Different from preview',
    IssueReportReason.confusingExplanation => 'Confusing explanation',
    IssueReportReason.translationError => 'Translation error',
    IssueReportReason.hardToRead => 'Hard to read',
  };
}

/// Payload sent to `POST /courses-reports`.
class IssueReportEntity {
  const IssueReportEntity({
    required this.lessonId,
    this.courseId = '',
    this.reasons = const [],
    this.comment = '',
  });

  final String lessonId;
  final String courseId;
  final List<IssueReportReason> reasons;
  final String comment;

  Map<String, dynamic> toJson() => {
    'lessonId': lessonId,
    if (courseId.trim().isNotEmpty) 'courseId': courseId.trim(),
    'reasons': reasons.map((reason) => reason.apiValue).toList(),
    if (comment.trim().isNotEmpty) 'comment': comment.trim(),
  };
}
