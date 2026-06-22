part of '../../../lesson.dart';

class IssueReportCubit extends Cubit<IssueReportState> {
  IssueReportCubit({
    required ReportIssueUseCase reportIssueUseCase,
    required this.lessonId,
    required this.courseId,
  })  : _reportIssueUseCase = reportIssueUseCase,
        super(const IssueReportState());

  final ReportIssueUseCase _reportIssueUseCase;
  final String lessonId;
  final String courseId;

  void toggleReason(IssueReportReason reason) {
    final next = Set<IssueReportReason>.from(state.selectedReasons);
    if (!next.add(reason)) next.remove(reason);
    emit(state.copyWith(selectedReasons: next, errorMessage: null));
  }

  void updateComment(String value) {
    emit(state.copyWith(comment: value));
  }

  Future<void> submit() async {
    if (!state.canSubmit) return;

    emit(state.copyWith(isSubmitting: true, errorMessage: null));

    final entity = IssueReportEntity(
      lessonId: lessonId,
      courseId: courseId,
      reasons: state.selectedReasons.toList(),
      comment: state.comment,
    );

    final result = await _reportIssueUseCase(entity).run();

    result.fold(
      (exception) => emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: exception.message ?? 'Failed to submit report',
        ),
      ),
      (_) => emit(state.copyWith(isSubmitting: false, isSuccess: true)),
    );
  }
}
