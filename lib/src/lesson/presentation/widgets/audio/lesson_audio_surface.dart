part of '../../../lesson.dart';

class LessonAudioSurface extends StatelessWidget {
  const LessonAudioSurface({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LessonAudioCubit, LessonAudioState>(
      builder: (context, state) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              // Static surface — the ConstrainedBox below only exists so short
              // content still centers instead of pinning to the top; it isn't
              // meant to be swipeable. NeverScrollableScrollPhysics keeps that
              // overflow-safety net (no error on very small screens) without
              // letting the user drag it around.
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 36.h),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    LessonAudioPlayerCard(
                      state: state,
                      onRetry: () => context.read<LessonAudioCubit>().retry(),
                      controls: LessonAudioControls(
                        isPlaying: state.isPlaying,
                        isLoading: state.isLoading,
                        canSeekBackward: state.canSeekBackward,
                        canSeekForward: state.canSeekForward,
                        onSeekBackward: () => _handleSeek(context, const Duration(seconds: -10)),
                        onPlayPause: () => _handlePlayPause(context, state),
                        onSeekForward: () => _handleSeek(context, const Duration(seconds: 10)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handlePlayPause(BuildContext context, LessonAudioState state) async {
    final trackingData = KeypointTrackingData.fromContext();
    final audioCubit = context.read<LessonAudioCubit>();

    if (state.isPlaying) {
      if (trackingData != null) {
        AppService.instance.appTrackingService.trackKeypointAudioPauseClick(
          trackingData,
          audioPosition: state.positionSeconds,
        );
      }
      await audioCubit.pause();
      return;
    }

    if (trackingData != null) {
      AppService.instance.appTrackingService.trackKeypointAudioPlayClick(trackingData);
    }
    await audioCubit.enterAudioMode();
  }

  Future<void> _handleSeek(BuildContext context, Duration delta) async {
    final state = context.read<LessonAudioCubit>().state;
    final trackingData = KeypointTrackingData.fromContext();
    final seekFrom = state.positionSeconds;
    final seekTo = (state.position + delta).inSeconds.clamp(0, state.durationSeconds);

    if (trackingData != null) {
      if (delta.isNegative) {
        AppService.instance.appTrackingService.trackKeypointAudioSeekBackClick(
          trackingData,
          seekFromSecond: seekFrom,
          seekToSecond: seekTo,
        );
      } else {
        AppService.instance.appTrackingService.trackKeypointAudioSeekForwardClick(
          trackingData,
          seekFromSecond: seekFrom,
          seekToSecond: seekTo,
        );
      }
    }

    await context.read<LessonAudioCubit>().seekBy(delta);
  }
}
