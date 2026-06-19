part of '../../../lesson.dart';

class IssueReportState {
  const IssueReportState({
    this.selectedReasons = const {},
    this.comment = '',
    this.isSubmitting = false,
    this.isSuccess = false,
    this.errorMessage,
  });

  final Set<IssueReportReason> selectedReasons;
  final String comment;
  final bool isSubmitting;
  final bool isSuccess;
  final String? errorMessage;

  bool get canSubmit => selectedReasons.isNotEmpty && !isSubmitting;

  IssueReportState copyWith({
    Set<IssueReportReason>? selectedReasons,
    String? comment,
    bool? isSubmitting,
    bool? isSuccess,
    Object? errorMessage = _sentinel,
  }) {
    return IssueReportState(
      selectedReasons: selectedReasons ?? this.selectedReasons,
      comment: comment ?? this.comment,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage == _sentinel ? this.errorMessage : errorMessage as String?,
    );
  }
}

const Object _sentinel = Object();
