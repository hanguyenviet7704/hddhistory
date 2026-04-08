part of '../../video_lesson.dart';

class _VideoLessonReadyView extends StatelessWidget {
  const _VideoLessonReadyView({
    required this.controller,
    required this.isInitializingController,
    required this.state,
    required this.onClose,
    required this.onPlayPause,
    required this.onSurfaceTap,
    required this.onNotesTap,
    required this.onSummaryTap,
    required this.onShareTap,
    required this.onSeekStart,
    required this.onSeekChanged,
    required this.onSeekEnd,
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

  final VideoPlayerController? controller;
  final bool isInitializingController;
  final VideoLessonState state;
  final VoidCallback onClose;
  final VoidCallback onPlayPause;
  final VoidCallback onSurfaceTap;
  final VoidCallback onNotesTap;
  final VoidCallback onSummaryTap;
  final VoidCallback onShareTap;
  final ValueChanged<double> onSeekStart;
  final ValueChanged<double> onSeekChanged;
  final ValueChanged<double> onSeekEnd;
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

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: state.activeOverlay == VideoLessonOverlay.none ? onSurfaceTap : null,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Color(0xFF0D121C)),
          Center(
            child: VideoLessonPlayerSurface(
              controller: controller,
              thumbnailUrl: state.lesson.video.thumbnail,
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.2),
                      Colors.black.withValues(alpha: 0.65),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (isInitializingController)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          VideoLessonPlayerControls(
            state: state,
            onClose: onClose,
            onPlayPause: onPlayPause,
            onSummaryTap: onSummaryTap,
            onNotesTap: onNotesTap,
            onShareTap: onShareTap,
            onSeekStart: onSeekStart,
            onSeekChanged: onSeekChanged,
            onSeekEnd: onSeekEnd,
          ),
          if (showOverlayScrim)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: state.isEndVisible,
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: state.isNotesVisible || state.isSummaryVisible ? 4 : 17,
                    sigmaY: state.isNotesVisible || state.isSummaryVisible ? 4 : 17,
                  ),
                  child: Container(
                    color: Colors.black.withValues(alpha: state.isNotesVisible || state.isSummaryVisible ? 0.38 : 0.6),
                  ),
                ),
              ),
            ),
          if (state.isNotesVisible)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onCloseNotes,
                child: const SizedBox.expand(),
              ),
            ),
          if (state.isSummaryVisible)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onCloseSummary,
                child: const SizedBox.expand(),
              ),
            ),
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
      ),
    );
  }
}

class _VideoLessonStatusView extends StatelessWidget {
  const _VideoLessonStatusView({
    required this.message,
    required this.onExit,
    this.onRetry,
  });

  final String message;
  final VoidCallback onExit;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppText(
              message,
              maxLines: 8,
              textAlign: TextAlign.center,
              style: AppStyle.text16.copyWith(
                color: Colors.white,
                height: 1.6,
              ),
            ),
            24.verticalSpace,
            if (onRetry != null) ...[
              AppButton.primary(
                onPressed: onRetry,
                fullWidthBtn: true,
                height: 54.h,
                borderRadius: BorderRadius.circular(1000.r),
                child: AppText(
                  context.l10n.videoLesson.retryLoadButton,
                  style: AppStyle.textBold16.copyWith(color: Colors.white),
                ),
              ),
              12.verticalSpace,
            ],
            AppButton.secondary(
              onPressed: onExit,
              fullWidthBtn: true,
              height: 54.h,
              borderRadius: BorderRadius.circular(1000.r),
              child: AppText(
                context.l10n.videoLesson.backButton,
                style: AppStyle.textBold16.copyWith(
                  color: AppCustomColor.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
