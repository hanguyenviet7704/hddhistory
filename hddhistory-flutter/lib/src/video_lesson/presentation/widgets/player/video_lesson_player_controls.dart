part of '../../../video_lesson.dart';

class VideoLessonPlayerControls extends StatelessWidget {
  const VideoLessonPlayerControls({
    super.key,
    required this.state,
    required this.onClose,
    required this.onPlayPause,
    required this.onSummaryTap,
    required this.onNotesTap,
    required this.onShareTap,
    required this.onSeekStart,
    required this.onSeekChanged,
    required this.onSeekEnd,
  });

  final VideoLessonState state;
  final VoidCallback onClose;
  final VoidCallback onPlayPause;
  final VoidCallback onSummaryTap;
  final VoidCallback onNotesTap;
  final VoidCallback onShareTap;
  final ValueChanged<double> onSeekStart;
  final ValueChanged<double> onSeekChanged;
  final ValueChanged<double> onSeekEnd;

  @override
  Widget build(BuildContext context) {
    final showBaseControls = state.activeOverlay == VideoLessonOverlay.none || state.isEndVisible;
    final showControls = showBaseControls && (!state.isPlaying || state.controlsVisible || state.isEndVisible);
    final canUseShare = state.activeOverlay == VideoLessonOverlay.none && !state.isEndVisible;
    final canUseNotes = canUseShare && !state.hasPendingSkippedQuestions;
    final canUseSummary = canUseShare && !state.hasPendingSkippedQuestions;
    final canSeek = state.activeOverlay == VideoLessonOverlay.none;

    return IgnorePointer(
      ignoring: !showControls,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _VideoLessonAnimatedVisibility(
            visible: showControls,
            hiddenOffset: const Offset(0, -0.14),
            child: _VideoLessonCloseButton(onClose: onClose),
          ),
          if (!state.isEndVisible)
            Positioned(
              right: 17.w,
              top: MediaQuery.viewPaddingOf(context).top + 439.h,
              child: _VideoLessonAnimatedVisibility(
                visible: showControls,
                hiddenOffset: const Offset(0.16, 0),
                child: _VideoLessonUtilityActionsColumn(
                  canUseSummary: canUseSummary,
                  canUseNotes: canUseNotes,
                  canUseShare: canUseShare,
                  onSummaryTap: onSummaryTap,
                  onNotesTap: onNotesTap,
                  onShareTap: onShareTap,
                ),
              ),
            ),
          if (!state.isEndVisible)
            Center(
              child: _VideoLessonAnimatedVisibility(
                visible: showControls,
                hiddenOffset: const Offset(0, 0.08),
                child: _VideoLessonPlaybackButton(
                  isPlaying: state.isPlaying,
                  onTap: onPlayPause,
                ),
              ),
            ),
          Positioned(
            left: 16.w,
            right: 16.w,
            bottom: 12.h + MediaQuery.viewPaddingOf(context).bottom,
            child: _VideoLessonAnimatedVisibility(
              visible: showControls,
              hiddenOffset: const Offset(0, 0.18),
              child: _VideoLessonProgressCluster(
                state: state,
                canSeek: canSeek,
                onSeekStart: onSeekStart,
                onSeekChanged: onSeekChanged,
                onSeekEnd: onSeekEnd,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
