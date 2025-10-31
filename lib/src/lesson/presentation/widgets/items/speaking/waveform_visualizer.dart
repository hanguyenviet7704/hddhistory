part of '../../../../lesson.dart';

/// Waveform Visualizer
/// Displays a waveform visualization using audio_waveforms package
/// Shows live waveform during recording, keeps it visible when paused or stopped
class WaveformVisualizer extends StatelessWidget {
  final RecorderController? recorderController;
  final SpeakingRecordingState recordingState;

  const WaveformVisualizer({
    super.key,
    this.recorderController,
    required this.recordingState,
  });

  @override
  Widget build(BuildContext context) {
    // Always use RecorderController - it preserves waveform when paused/stopped
    if (recorderController == null) return const SizedBox.shrink();
    return Center(
      child: AudioWaveforms(
        size: Size(0.4.sw, 40.h),
        recorderController: recorderController!,
        enableGesture: false,
        shouldCalculateScrolledPosition: false,
        waveStyle: WaveStyle(
          waveColor: const Color(0xFF554FF0),
          spacing: 6.w,
          showBottom: true,
          showTop: true,
          extendWaveform: true,
          showMiddleLine: false,
          waveCap: StrokeCap.round,
          waveThickness: 4.w,
        ),
      ),
    );
  }
}
