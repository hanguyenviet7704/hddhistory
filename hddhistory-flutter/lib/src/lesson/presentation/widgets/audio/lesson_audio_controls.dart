part of '../../../lesson.dart';

class LessonAudioControls extends StatelessWidget {
  const LessonAudioControls({
    super.key,
    required this.isPlaying,
    required this.isLoading,
    required this.canSeekBackward,
    required this.canSeekForward,
    required this.onSeekBackward,
    required this.onPlayPause,
    required this.onSeekForward,
  });

  final bool isPlaying;
  final bool isLoading;
  final bool canSeekBackward;
  final bool canSeekForward;
  final VoidCallback onSeekBackward;
  final VoidCallback onPlayPause;
  final VoidCallback onSeekForward;

  @override
  Widget build(BuildContext context) {
    // Reading/listening transport bar — a light tap on every control so
    // play/pause and seeking feel physical.
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LessonAudioControlIconButton(
          assetPath: AppAsset.svg.app.icBack10s,
          enabled: canSeekBackward,
          onTap: () {
            AppHaptic.select();
            onSeekBackward();
          },
        ),
        SizedBox(width: 36.w),
        _LessonAudioPlayPauseButton(
          isPlaying: isPlaying,
          isLoading: isLoading,
          onTap: () {
            AppHaptic.select();
            onPlayPause();
          },
        ),
        SizedBox(width: 36.w),
        _LessonAudioControlIconButton(
          assetPath: AppAsset.svg.app.icNext10s,
          enabled: canSeekForward,
          onTap: () {
            AppHaptic.select();
            onSeekForward();
          },
        ),
      ],
    );
  }
}

class _LessonAudioControlIconButton extends StatelessWidget {
  const _LessonAudioControlIconButton({
    required this.assetPath,
    required this.enabled,
    required this.onTap,
  });

  final String assetPath;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: SizedBox(
          width: 30.w,
          height: 30.h,
          child: SvgPicture.asset(
            assetPath,
            colorFilter: const ColorFilter.mode(
              Color(0xFFAAB8CD),
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}

class _LessonAudioPlayPauseButton extends StatelessWidget {
  const _LessonAudioPlayPauseButton({
    required this.isPlaying,
    required this.isLoading,
    required this.onTap,
  });

  final bool isPlaying;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 58.r,
        height: 58.r,
        decoration: const BoxDecoration(
          color: Color(0xFF0D121C),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 160),
          child: isLoading
              ? SizedBox(
                  key: const ValueKey('lesson-audio-loading'),
                  width: 22.w,
                  height: 22.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4.w,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  key: ValueKey('lesson-audio-playback-$isPlaying'),
                  color: Colors.white,
                  size: isPlaying ? 28.sp : 34.sp,
                ),
        ),
      ),
    );
  }
}
