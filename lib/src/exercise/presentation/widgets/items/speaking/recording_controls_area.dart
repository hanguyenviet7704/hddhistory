part of '../../../../exercise.dart';

/// Recording Controls Area
/// Displays recording controls including play/pause, timer, waveform, and send/stop button
class RecordingControlsArea extends StatelessWidget {
  const RecordingControlsArea({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SpeakingCubit>().state;
    final canSubmit = state.audioFilePath != null;

    return Container(
      height: 54.h,
      padding: EdgeInsets.only(left: 12.w, right: 8.w),
      decoration: BoxDecoration(
        color: const Color(0xFFEBEAFD),
        borderRadius: BorderRadius.circular(1000.r),
      ),
      child: Row(
        children: [
          // Play/Pause button
          // GestureDetector(
          //   onTap: canSubmit ? () => context.read<SpeakingCubit>().playRecording() : null,
          //   child: Container(
          //     width: 32.w,
          //     height: 32.w,
          //     decoration: BoxDecoration(
          //       color: canSubmit ? const Color(0xFF554FF0).withValues(alpha: 0.1) : Colors.transparent,
          //       shape: BoxShape.circle,
          //     ),
          //     child: Icon(
          //       state.isPlaying ? Icons.pause : Icons.play_arrow,
          //       size: 20.w,
          //       color: const Color(0xFF554FF0),
          //     ),
          //   ),
          // ),
          GestureDetector(
            onTap: () {
              if (!canSubmit) return;
              if (state.isPlaying) {
                context.read<SpeakingCubit>().pausePlayback();
                return;
              }
              if (state.isPaused) {
                context.read<SpeakingCubit>().playRecording();
                return;
              }
              if (state.isPlaying) {
                context.read<SpeakingCubit>().playRecording();
              }
            },
            child: BlocBuilder<SpeakingCubit, SpeakingState>(
              buildWhen: (previous, current) => previous.recordingProgress != current.recordingProgress || previous.isPlaying != current.isPlaying,
              builder: (context, state) {
                return CircularPercentIndicator(
                  radius: 16.w,
                  lineWidth: 6.w,
                  animateFromLastPercent: true,
                  percent: state.recordingProgress,
                  progressColor: const Color(0xFF554FF0),
                  backgroundColor: const Color(0x66554FF0),
                  circularStrokeCap: CircularStrokeCap.round,
                  center: Icon(
                    state.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 20.w,
                    color: const Color(0xFF554FF0),
                  ),
                );
              },
            ),
          ),
          12.horizontalSpace,
          // Timer
          AppText(
            state.recordingDuration.formatDuration,
            style: AppStyle.textBold14.copyWith(
              color: const Color(0xFF554FF0).withValues(alpha: 0.4),
            ),
          ),
          12.horizontalSpace,
          // Waveform
          Expanded(
            child: WaveformVisualizer(isRecording: state.isRecording),
          ),
          8.horizontalSpace,
          // Send/Stop button
          GestureDetector(
            onTap: () {
              // if (state.isRecording) {
              //   context.read<SpeakingCubit>().stopRecording();
              //   return;
              // }

              if (!canSubmit) return;
              context.read<SpeakingCubit>().submitAnswer();
            },
            child: Container(
              padding: EdgeInsets.all(8.w),
              decoration: const BoxDecoration(
                color: Color(0xFF554FF0),
                shape: BoxShape.circle,
              ),
              child: SvgPicture.asset(
                AppAsset.svg.app.icSend,
                width: 24.w,
                height: 24.w,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
