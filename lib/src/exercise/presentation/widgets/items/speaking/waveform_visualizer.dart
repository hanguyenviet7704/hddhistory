part of '../../../../exercise.dart';

/// Waveform Visualizer
/// Displays a waveform visualization using audio_waveforms package
/// Shows live waveform during recording, pauses when paused, and shows static waveform when idle
class WaveformVisualizer extends StatelessWidget {
  final RecorderController recorderController;


  const WaveformVisualizer({
    super.key,
    required this.recorderController,
  });

  @override
  Widget build(BuildContext context) {
    return AudioWaveforms(
      size: Size(double.infinity, 30.h),
      recorderController: recorderController,
      enableGesture: false,
      waveStyle: WaveStyle(
        waveColor: const Color(0xFF554FF0),
        spacing: 4.w,
        showBottom: false,
        showTop: false,
        extendWaveform: true,
        showMiddleLine: false,
        waveCap: StrokeCap.round,
        waveThickness: 3.w,
      ),
    );
  }
}
