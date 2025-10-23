part of '../../../../../exercise.dart';

class RecordingControl extends StatelessWidget {
  final RecorderController recorderController;
  final PlayerController? playerController;
  final bool hasRecording;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;
  final VoidCallback onCancelRecording;
  final VoidCallback onTogglePlayback;
  final VoidCallback onResetRecording;

  const RecordingControl({
    super.key,
    required this.recorderController,
    this.playerController,
    required this.hasRecording,
    required this.onStartRecording,
    required this.onStopRecording,
    required this.onCancelRecording,
    required this.onTogglePlayback,
    required this.onResetRecording,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RecorderState>(
      stream: recorderController.onRecorderStateChanged,
      initialData: RecorderState.stopped,
      builder: (context, snapshot) {
        final isRecording = snapshot.data == RecorderState.recording;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(24))),
          child: isRecording
              ? _buildRecordingState()
              : hasRecording
              ? _buildPlaybackState()
              : _buildIdleState(),
        );
      },
    );
  }

  Widget _buildIdleState() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          onStartRecording();
        },
        borderRadius: BorderRadius.circular(1000),
        child: Container(
          height: 54,
          decoration: BoxDecoration(color: const Color(0xFFEBEAFD), borderRadius: BorderRadius.circular(1000)),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.mic, color: Color(0xFF554FF0), size: 24),
              SizedBox(width: 10),
              Text(
                'Tap to speak',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF554FF0)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingState() {
    return Row(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onCancelRecording,
            borderRadius: BorderRadius.circular(1000),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: const Color(0xFFEEF2F6), borderRadius: BorderRadius.circular(1000)),
              child: const Icon(Icons.close, color: Color(0xFF7F8EA4), size: 24),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            height: 54,
            padding: const EdgeInsets.only(left: 16, right: 8),
            decoration: BoxDecoration(color: const Color(0xFFEBEAFD), borderRadius: BorderRadius.circular(1000)),
            child: Row(
              children: [
                StreamBuilder<Duration>(
                  stream: recorderController.onCurrentDuration,
                  builder: (context, snapshot) {
                    final duration = snapshot.data ?? Duration.zero;
                    final minutes = duration.inMinutes.toString().padLeft(2, '0');
                    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
                    return Text(
                      '$minutes:$seconds',
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF554FF0)),
                    );
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AudioWaveforms(
                    size: const Size(double.infinity, 30),
                    recorderController: recorderController,
                    enableGesture: false,
                    waveStyle: const WaveStyle(
                      waveColor: Color(0xFF554FF0),
                      spacing: 4.918,
                      showBottom: true,
                      extendWaveform: true,
                      showMiddleLine: false,
                      waveThickness: 3.279,
                      waveCap: StrokeCap.round,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onStopRecording,
                    borderRadius: BorderRadius.circular(1000),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: const Color(0xFF554FF0), borderRadius: BorderRadius.circular(1000)),
                      child: const Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaybackState() {
    if (playerController == null) return const SizedBox();

    return StreamBuilder<PlayerState>(
      stream: playerController!.onPlayerStateChanged,
      initialData: PlayerState.stopped,
      builder: (context, snapshot) {
        final isPlaying = snapshot.data == PlayerState.playing;

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onResetRecording,
                    borderRadius: BorderRadius.circular(1000),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(color: const Color(0xFFFF4B4B), borderRadius: BorderRadius.circular(1000)),
                      child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 28),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: const Color(0xFF1CB0F6).withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 4))],
                  ),
                  child: IconButton(
                    iconSize: 40,
                    icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: const Color(0xFF1CB0F6)),
                    onPressed: onTogglePlayback,
                  ),
                ),
                const SizedBox(width: 24),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(1000),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(color: const Color(0xFF58CC02), borderRadius: BorderRadius.circular(1000)),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 28),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            StreamBuilder<int>(
              stream: playerController!.onCurrentDurationChanged,
              builder: (context, snapshot) {
                final currentMs = snapshot.data ?? 0;
                final currentPosition = Duration(milliseconds: currentMs);
                final totalDuration = Duration(milliseconds: playerController!.maxDuration);
                final remainingDuration = totalDuration - currentPosition;

                return Row(
                  children: [
                    Text(
                      _formatDuration(currentPosition),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2C3E50)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                          activeTrackColor: const Color(0xFF1CB0F6),
                          inactiveTrackColor: const Color(0xFFE0E6ED),
                          thumbColor: const Color(0xFF1CB0F6),
                          overlayColor: const Color(0xFF1CB0F6).withValues(alpha: 0.2),
                        ),
                        child: Slider(
                          value: currentMs.toDouble(),
                          min: 0,
                          max: playerController!.maxDuration.toDouble() > 0 ? playerController!.maxDuration.toDouble() : 1,
                          onChanged: (value) async {
                            await playerController!.seekTo(value.toInt());
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '-${_formatDuration(remainingDuration)}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF5D7285)),
                    ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
