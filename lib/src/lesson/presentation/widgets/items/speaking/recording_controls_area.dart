part of '../../../../lesson.dart';

/// Recording Controls Area
/// Displays recording controls including play/pause, timer, waveform, and send/stop button
class RecordingControlsArea extends StatelessWidget {
  const RecordingControlsArea({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
            width: 80.w,
            height: 80.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                width: 2.67.w,
                color: const Color(0xFF554FF0) /* Brand-Brand-Primary-500 */,
              ),
            ),
            child: Icon(
              isRecording ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: const Color(0xFF554FF0),
              size: 52.sp,
            ),
          );
        },
      ),
    );
  }
}
