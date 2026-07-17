part of '../../../../lesson.dart';

/// Recording Controls Area
/// Displays recording controls including play/pause, timer, waveform, and send/stop button
class RecordingControlsArea extends StatelessWidget {
  final SpeakingRecordingState recordingState;
  final VoidCallback? onTap;

  const RecordingControlsArea({
    super.key,
    required this.recordingState,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isRecording = recordingState == SpeakingRecordingState.recording;
    final isPaused = recordingState == SpeakingRecordingState.paused;
    final isEnabled = isRecording || isPaused;

    return GestureDetector(
      onTap: isEnabled && onTap != null
          ? () {
              AppHaptic.select();
              onTap!();
            }
          : null,
      child: Container(
        width: 80.w,
        height: 80.w,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            width: 2.67.w,
            color: isEnabled ? const Color(0xFF554FF0) : const Color(0xFFAAB7CC),
          ),
        ),
        child: Icon(
          isRecording ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: isEnabled ? const Color(0xFF554FF0) : const Color(0xFFAAB7CC),
          size: 52.sp,
        ),
      ),
    );
  }
}
