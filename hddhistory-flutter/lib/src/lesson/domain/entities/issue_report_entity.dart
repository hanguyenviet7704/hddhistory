part of '../../lesson.dart';

class IssueReportEntity {
  const IssueReportEntity({
    required this.lessonId,
    required this.keypointId,
    required this.keypointTitle,
    required this.keypointImage,
    required this.reasons,
    this.comment = '',
  });

  final String lessonId;
  final String keypointId;
  final String keypointTitle;
  final String keypointImage;
  final List<IssueReportReason> reasons;
  final String comment;
}

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

  String label(BuildContext context) => switch (this) {
    IssueReportReason.inaccurateContent => context.l10n.lessonReport.inaccurateContent,
    IssueReportReason.differentFromPreview => context.l10n.lessonReport.differentFromPreview,
    IssueReportReason.confusingExplanation => context.l10n.lessonReport.confusingExplanation,
    IssueReportReason.translationError => context.l10n.lessonReport.translationError,
    IssueReportReason.hardToRead => context.l10n.lessonReport.hardToRead,
  };
}
