part of '../../../lesson.dart';

enum ReportIssueStatus { initial, loading, success, failure }

@freezed
abstract class ReportIssueState with _$ReportIssueState {
  const factory ReportIssueState({
    @Default(ReportIssueStatus.initial) ReportIssueStatus status,
    @Default([]) List<IssueReportReason> selectedReasons,
    @Default('') String comment,
    String? errorMessage,
  }) = _ReportIssueState;

  factory ReportIssueState.initial() => const ReportIssueState();
}

extension ReportIssueStateExtension on ReportIssueState {
  bool get isLoading => status == ReportIssueStatus.loading;

  bool get canSubmit => selectedReasons.isNotEmpty && !isLoading;
}
