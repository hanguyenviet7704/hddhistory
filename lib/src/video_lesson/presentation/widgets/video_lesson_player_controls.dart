part of '../../video_lesson.dart';

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
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
              child: _VideoLessonAnimatedVisibility(
                visible: showControls,
                hiddenOffset: const Offset(0, -0.14),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: _VideoLessonPressableScale(
                    onTap: onClose,
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      width: 32.r,
                      height: 32.r,
                      child: Center(
                        child: SvgPicture.asset(
                          AppAsset.svg.app.icClose,
                          width: 20.w,
                          height: 20.w,
                          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (!state.isEndVisible)
            Positioned(
              right: 16.w,
              top: 0,
              bottom: 92.h,
              child: _VideoLessonAnimatedVisibility(
                visible: showControls,
                hiddenOffset: const Offset(0.16, 0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _VideoLessonUtilityButton(
                      icon: Icons.menu_book_rounded,
                      enabled: canUseSummary,
                      onTap: onSummaryTap,
                    ),
                    SizedBox(height: 32.h),
                    _VideoLessonUtilityButton(
                      icon: Icons.sticky_note_2_outlined,
                      enabled: canUseNotes,
                      onTap: onNotesTap,
                    ),
                    SizedBox(height: 32.h),
                    _VideoLessonUtilityButton(
                      icon: Icons.share_outlined,
                      enabled: canUseShare,
                      onTap: onShareTap,
                    ),
                  ],
                ),
              ),
            ),
          if (!state.isEndVisible)
            Center(
              child: _VideoLessonAnimatedVisibility(
                visible: showControls,
                hiddenOffset: const Offset(0, 0.08),
                child: _VideoLessonPressableScale(
                  onTap: onPlayPause,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 72.r,
                    height: 72.r,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.02),
                      shape: BoxShape.circle,
                    ),
                    child: AnimatedSwitcher(
                      duration: _videoLessonFastAnimationDuration,
                      switchInCurve: _videoLessonEntranceCurve,
                      switchOutCurve: _videoLessonExitCurve,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.86, end: 1).animate(animation),
                          child: child,
                        ),
                      ),
                      child: Icon(
                        state.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        key: ValueKey('video-lesson-playback-icon-${state.isPlaying}'),
                        size: 42.r,
                        color: Colors.white,
                      ),
                    ),
                  ),
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

class _VideoLessonUtilityButton extends StatelessWidget {
  const _VideoLessonUtilityButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 0.92 : 0.38,
      child: _VideoLessonPressableScale(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : null,
        child: SizedBox.square(
          dimension: 32.r,
          child: Icon(
            icon,
            color: Colors.white,
            size: 28.r,
          ),
        ),
      ),
    );
  }
}

class _VideoLessonProgressCluster extends StatelessWidget {
  const _VideoLessonProgressCluster({
    required this.state,
    required this.canSeek,
    required this.onSeekStart,
    required this.onSeekChanged,
    required this.onSeekEnd,
  });

  final VideoLessonState state;
  final bool canSeek;
  final ValueChanged<double> onSeekStart;
  final ValueChanged<double> onSeekChanged;
  final ValueChanged<double> onSeekEnd;

  @override
  Widget build(BuildContext context) {
    final maxSeconds = max(state.durationSeconds.toDouble(), 1.0).toDouble();
    final value = state.positionSeconds.clamp(0, state.durationSeconds).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 16.h,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 8.h,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
              activeTrackColor: const Color(0xFF2B7FFF),
              thumbColor: const Color(0xFF2B7FFF),
              overlayShape: SliderComponentShape.noOverlay,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8.r),
            ),
            child: Slider(
              value: value.clamp(0, maxSeconds).toDouble(),
              max: maxSeconds,
              onChangeStart: canSeek ? onSeekStart : null,
              onChanged: canSeek ? onSeekChanged : null,
              onChangeEnd: canSeek ? onSeekEnd : null,
            ),
          ),
        ),
        8.verticalSpace,
        AppText(
          state.playbackLabel,
          style: AppStyle.text14.copyWith(
            color: Colors.white,
            height: 1.75,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
