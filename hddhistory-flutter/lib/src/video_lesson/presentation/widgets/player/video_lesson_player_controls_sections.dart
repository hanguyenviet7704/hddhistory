part of '../../../video_lesson.dart';

class _VideoLessonCloseButton extends StatelessWidget {
  const _VideoLessonCloseButton({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
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
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VideoLessonUtilityActionsColumn extends StatelessWidget {
  const _VideoLessonUtilityActionsColumn({
    required this.canUseSummary,
    required this.canUseNotes,
    required this.canUseShare,
    required this.onSummaryTap,
    required this.onNotesTap,
    required this.onShareTap,
  });

  final bool canUseSummary;
  final bool canUseNotes;
  final bool canUseShare;
  final VoidCallback onSummaryTap;
  final VoidCallback onNotesTap;
  final VoidCallback onShareTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _VideoLessonUtilityButton(
          buttonKey: const Key('video-lesson-summary-button'),
          assetPath: AppAsset.svg.app.icOpenbook,
          iconWidth: 24.5,
          iconHeight: 28,
          enabled: canUseSummary,
          onTap: onSummaryTap,
        ),
        SizedBox(height: 32.h),
        _VideoLessonUtilityButton(
          buttonKey: const Key('video-lesson-notes-button'),
          assetPath: AppAsset.svg.app.icNote,
          iconWidth: 27,
          iconHeight: 24,
          enabled: canUseNotes,
          onTap: onNotesTap,
        ),
        SizedBox(height: 32.h),
        _VideoLessonUtilityButton(
          buttonKey: const Key('video-lesson-share-button'),
          assetPath: AppAsset.svg.app.icShare,
          iconWidth: 32,
          iconHeight: 32,
          enabled: canUseShare,
          onTap: onShareTap,
        ),
      ],
    );
  }
}

class _VideoLessonPlaybackButton extends StatelessWidget {
  const _VideoLessonPlaybackButton({
    required this.isPlaying,
    required this.onTap,
  });

  final bool isPlaying;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _VideoLessonPressableScale(
      onTap: onTap,
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
            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            key: ValueKey('video-lesson-playback-icon-$isPlaying'),
            size: 42.r,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _VideoLessonUtilityButton extends StatelessWidget {
  const _VideoLessonUtilityButton({
    required this.buttonKey,
    required this.assetPath,
    required this.iconWidth,
    required this.iconHeight,
    required this.enabled,
    required this.onTap,
  });

  final Key buttonKey;
  final String assetPath;
  final double iconWidth;
  final double iconHeight;
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
          key: buttonKey,
          dimension: 32.r,
          child: Center(
            child: SvgPicture.asset(
              assetPath,
              width: iconWidth.w,
              height: iconHeight.h,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
