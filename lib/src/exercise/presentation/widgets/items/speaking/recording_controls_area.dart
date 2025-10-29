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
          GestureDetector(
            onTap: canSubmit
                ? () => context.read<SpeakingCubit>().playRecording()
                : null,
            child: Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: canSubmit
                    ? const Color(0xFF554FF0).withValues(alpha: 0.1)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                state.isPlaying ? Icons.pause : Icons.play_arrow,
                size: 20.w,
                color: const Color(0xFF554FF0),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          // Timer
          Text(
            _formatDuration(state.recordingDuration),
            style: AppStyle.text14.copyWith(
              color: const Color(0xFF554FF0).withValues(alpha: 0.4),
            ),
          ),
          SizedBox(width: 12.w),
          // Waveform
          Expanded(
            child: WaveformVisualizer(isRecording: state.isRecording),
          ),
          SizedBox(width: 8.w),
          // Send/Stop button
          GestureDetector(
            onTap: () {
              if (state.isRecording) {
                context.read<SpeakingCubit>().stopRecording();
              } else if (canSubmit) {
                context.read<SpeakingCubit>().submitAnswer();
              }
            },
            child: Container(
              width: 40.w,
              height: 40.w,
              decoration: const BoxDecoration(
                color: Color(0xFF554FF0),
                shape: BoxShape.circle,
              ),
              child: Icon(
                state.isRecording ? Icons.stop : Icons.send,
                size: 20.w,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
