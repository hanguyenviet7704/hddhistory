part of '../../../../exercise.dart';

/// Waveform Visualizer
/// Displays an animated waveform visualization during recording
class WaveformVisualizer extends StatefulWidget {
  final bool isRecording;

  const WaveformVisualizer({super.key, required this.isRecording});

  @override
  State<WaveformVisualizer> createState() => _WaveformVisualizerState();
}

class _WaveformVisualizerState extends State<WaveformVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<double> _waveformHeights = [
    9.836,
    11.639,
    30,
    20.82,
    20.82,
    11.639,
    6.393,
    3.279,
    3.279,
    3.279,
    3.279,
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_waveformHeights.length, (index) {
            final animValue = widget.isRecording
                ? (sin((_controller.value * 2 * pi) + (index * 0.5)) + 1) / 2
                : 0.3;
            final height = _waveformHeights[index] * animValue;

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 2.w),
              child: Container(
                width: 3.279.w,
                height: height.h,
                decoration: BoxDecoration(
                  color: const Color(0xFF554FF0),
                  borderRadius: BorderRadius.circular(4.918.r),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
