part of '../../../video_lesson.dart';

class _VideoLessonOverlayStack extends StatelessWidget {
  const _VideoLessonOverlayStack({
    required this.state,
    required this.onCloseNotes,
    required this.onCloseSummary,
    required this.onSummaryScroll,
    required this.onRetryNotes,
    required this.onLoadMoreNotes,
    required this.onAddNote,
    required this.onBackFromNoteEditor,
    required this.onSaveNote,
    required this.onDraftChanged,
    required this.onEditNote,
    required this.onDeleteNote,
    required this.onQuestionAnswerTap,
    required this.onSubmitQuestion,
    required this.onContinueAfterQuestion,
    required this.onComplete,
  });

  final VideoLessonState state;
  final VoidCallback onCloseNotes;
  final VoidCallback onCloseSummary;
  final VoidCallback onSummaryScroll;
  final VoidCallback onRetryNotes;
  final VoidCallback onLoadMoreNotes;
  final VoidCallback onAddNote;
  final VoidCallback onBackFromNoteEditor;
  final VoidCallback onSaveNote;
  final ValueChanged<String> onDraftChanged;
  final ValueChanged<UserVideoLessonNoteEntity> onEditNote;
  final ValueChanged<UserVideoLessonNoteEntity> onDeleteNote;
  final ValueChanged<int> onQuestionAnswerTap;
  final VoidCallback onSubmitQuestion;
  final VoidCallback onContinueAfterQuestion;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final showOverlayScrim = state.isNotesVisible || state.isSummaryVisible || state.isQuestionVisible || state.isQuestionResultVisible || state.isEndVisible;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (showOverlayScrim) _VideoLessonOverlayScrim(state: state),
        if (state.isNotesVisible) _VideoLessonOverlayDismissArea(onTap: onCloseNotes),
        if (state.isSummaryVisible) _VideoLessonOverlayDismissArea(onTap: onCloseSummary),
        if (state.isNotesVisible)
          VideoLessonNotesSheet(
            state: state,
            onClose: onCloseNotes,
            onBack: onBackFromNoteEditor,
            onAddNote: onAddNote,
            onSave: onSaveNote,
            onRetry: onRetryNotes,
            onLoadMore: onLoadMoreNotes,
            onDraftChanged: onDraftChanged,
            onEditNote: onEditNote,
            onDeleteNote: onDeleteNote,
          ),
        if (state.isSummaryVisible)
          VideoLessonSummarySheet(
            summary: state.lesson.video.summary.text,
            onClose: onCloseSummary,
            onScroll: onSummaryScroll,
          ),
        if (state.isQuestionVisible)
          VideoLessonQuestionSheet(
            state: state,
            onAnswerTap: onQuestionAnswerTap,
            onSubmit: onSubmitQuestion,
          ),
        if (state.isQuestionResultVisible)
          VideoLessonQuestionResultSheet(
            state: state,
            onContinue: onContinueAfterQuestion,
          ),
        if (state.isEndVisible)
          VideoLessonEndSheet(
            lesson: state.lesson,
            isSubmitting: state.completionStatus == VideoLessonCompletionStatus.loading,
            errorMessage: state.completionErrorMessage,
            onSubmit: onComplete,
          ),
      ],
    );
  }
}

class _VideoLessonOverlayScrim extends StatelessWidget {
  const _VideoLessonOverlayScrim({required this.state});

  final VideoLessonState state;

  @override
  Widget build(BuildContext context) {
    final isSheetOverlay = state.isNotesVisible || state.isSummaryVisible;

    return Positioned.fill(
      child: IgnorePointer(
        ignoring: state.isEndVisible,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: isSheetOverlay ? 4 : 17,
            sigmaY: isSheetOverlay ? 4 : 17,
          ),
          child: Container(
            color: Colors.black.withValues(
              alpha: isSheetOverlay ? 0.38 : 0.6,
            ),
          ),
        ),
      ),
    );
  }
}

class _VideoLessonOverlayDismissArea extends StatelessWidget {
  const _VideoLessonOverlayDismissArea({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: const SizedBox.expand(),
      ),
    );
  }
}
