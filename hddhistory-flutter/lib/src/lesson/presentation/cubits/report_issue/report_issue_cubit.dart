part of '../../../lesson.dart';

class ReportIssueCubit extends Cubit<ReportIssueState> with CubitUseCaseHandlerMixin<ReportIssueState> {
  final SubmitIssueReportUseCase _submitUseCase;

  ReportIssueCubit(this._submitUseCase) : super(ReportIssueState.initial());

  void toggleReason(IssueReportReason reason) {
    final updated = [...state.selectedReasons];
    if (updated.contains(reason)) {
      updated.remove(reason);
    } else {
      updated.add(reason);
    }
    emit(state.copyWith(selectedReasons: updated));
  }

  void updateComment(String comment) => emit(state.copyWith(comment: comment));

  void submit({
    required String lessonId,
    required String keypointId,
    required String keypointTitle,
    required String keypointImage,
  }) async {
    if (!state.canSubmit) return;
    final entity = IssueReportEntity(
      lessonId: lessonId,
      keypointId: keypointId,
      keypointTitle: keypointTitle,
      keypointImage: keypointImage,
      reasons: state.selectedReasons,
      comment: state.comment,
    );
    await runUseCase<Unit>(
      usecase: () => _submitUseCase(entity),
      buildLoadingState: () => state.copyWith(status: ReportIssueStatus.loading),
      onFailure: (error) => emit(state.copyWith(status: ReportIssueStatus.failure, errorMessage: error)),
      onSuccess: (_) => emit(state.copyWith(status: ReportIssueStatus.success)),
    );
  }

  void reset() => emit(ReportIssueState.initial());
}
