part of '../../../../lesson.dart';

/// Recording Controls Area
/// Displays recording controls including play/pause, timer, waveform, and send/stop button
class RecordingControlsArea extends StatelessWidget {
  const RecordingControlsArea({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54.h,
      padding: EdgeInsets.only(left: 12.w, right: 8.w),
      decoration: BoxDecoration(
        color: const Color(0xFFEBEAFD),
        borderRadius: BorderRadius.circular(1000.r),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              final state = context.read<SpeakingCubit>().state;

              if (state.recordingState == SpeakingRecordingState.recording) {
                context.read<SpeakingCubit>().pauseRecording();
                return;
              }

              if (state.recordingState == SpeakingRecordingState.paused) {
                context.read<SpeakingCubit>().resumeRecording();
                return;
              }
            },
            child: BlocSelector<SpeakingCubit, SpeakingState, bool>(
              selector: (state) => state.recordingState == SpeakingRecordingState.recording,
              builder: (context, isRecording) {
                return Container(
                  width: 40.w,
                  height: 40.w,
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC7C5FA),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isRecording ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: const Color(0xFF554FF0),
                  ),
                );
              },
            ),
          ),
          12.horizontalSpace,
          // Timer
          StreamBuilder<Duration>(
            stream: context.read<SpeakingCubit>().recorderController!.onCurrentDuration,
            builder: (context, snapshot) {
              final duration = snapshot.data ?? Duration.zero;
              return AppText(
                duration.formatDuration,
                style: AppStyle.textBold14.copyWith(
                  color: const Color(0xFF554FF0).withValues(alpha: 0.4),
                ),
              );
            }
          ),
          12.horizontalSpace,
          // Waveform
          Expanded(
            child: BlocBuilder<SpeakingCubit, SpeakingState>(
              builder: (context, state) {
                final cubit = context.read<SpeakingCubit>();
                return WaveformVisualizer(
                  recorderController: cubit.recorderController,
                  recordingState: state.recordingState,
                );
              },
            ),
          ),
          8.horizontalSpace,
          // Send/Stop button
          GestureDetector(
            onTap: () {
              // if (state.isRecording) {
              //   context.read<SpeakingCubit>().stopRecording();
              //   return;
              // }

              final state = context.read<SpeakingCubit>().state;
              final canSubmit = state.audioFilePath != null;
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
