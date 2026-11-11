part of '../../../video_lesson.dart';

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
