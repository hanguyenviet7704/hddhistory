part of '../../../exercise.dart';

class SpeakingLessonBody extends StatefulWidget {
  final String sentence;
  final String audioPath;
  final Function(bool isCompleted) onAnswerChecked;

  const SpeakingLessonBody({
    super.key,
    required this.sentence,
    required this.audioPath,
    required this.onAnswerChecked,
  });

  @override
  State<SpeakingLessonBody> createState() => _SpeakingLessonBodyState();
}

class _SpeakingLessonBodyState extends State<SpeakingLessonBody> {
  late RecorderController _recorderController;
  PlayerController? _playerController;
  PlayerController? _audioPlayerController;
  String? _recordingPath;
  bool _hasRecording = false;
  bool _isPlayingAudio = false;

  @override
  void initState() {
    super.initState();
    _initializeRecorder();
    _initializeAudioPlayer();
  }

  Future<void> _initializeRecorder() async {
    _recorderController = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
      ..sampleRate = 44100;
    await _checkPermission();
  }

  Future<void> _initializeAudioPlayer() async {
    _audioPlayerController = PlayerController();
    if (widget.audioPath.isNotEmpty) {
      await _audioPlayerController!.preparePlayer(path: widget.audioPath);
    }
  }

  Future<void> _initializePlayer() async {
    _playerController = PlayerController();
    if (_recordingPath != null) {
      await _playerController!.preparePlayer(path: _recordingPath!, shouldExtractWaveform: true);
    }
  }

  @override
  void dispose() {
    _recorderController.dispose();
    _playerController?.dispose();
    _audioPlayerController?.dispose();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.microphone.status;
    if (!status.isGranted) {
      final result = await Permission.microphone.request();
      if (result != PermissionStatus.granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Microphone permission is required to record audio')));
      }
    }
  }

  Future<void> _startRecording() async {
    try {
      if (_recorderController.isRecording) {
        return;
      }

      final hasPermission = await Permission.microphone.isGranted;
      if (!hasPermission) {
        await _checkPermission();
      }

      final directory = await getApplicationDocumentsDirectory();
      _recordingPath = '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorderController.record(path: _recordingPath);

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error starting recording: $e')));
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _recorderController.stop();
      if (path != null) {
        _recordingPath = path;
        setState(() {
          _hasRecording = true;
        });
        await _initializePlayer();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error stopping recording: $e')));
      }
    }
  }

  Future<void> _cancelRecording() async {
    await _recorderController.stop();
    _recorderController.refresh();
    setState(() {
      _hasRecording = false;
      _recordingPath = null;
    });
  }

  Future<void> _togglePlayback() async {
    if (_playerController == null) return;

    if (_playerController!.playerState == PlayerState.playing) {
      await _playerController!.pausePlayer();
    } else {
      await _playerController!.startPlayer();
    }
  }

  Future<void> _resetRecording() async {
    await _playerController?.stopPlayer();
    _playerController?.dispose();
    _playerController = null;

    setState(() {
      _hasRecording = false;
      _recordingPath = null;
    });

    _recorderController.refresh();
  }

  Future<void> _toggleAudioPlayback() async {
    if (_audioPlayerController == null) return;

    if (_isPlayingAudio) {
      await _audioPlayerController!.pausePlayer();
      setState(() {
        _isPlayingAudio = false;
      });
    } else {
      await _audioPlayerController!.startPlayer();
      setState(() {
        _isPlayingAudio = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Practice tag
        const SpeakingPracticeTag(),
        const SizedBox(height: 8),

        // Instruction bubble
        SpeakingInstructionBubble(
          instruction: 'Listen to this statement and practice',
        ),
        const SizedBox(height: 12),

        // Audio player card
        SpeakingAudioCard(
          isPlaying: _isPlayingAudio,
          onPlayPressed: _toggleAudioPlayback,
        ),
        const SizedBox(height: 20),

        // Recording control
        SpeakingRecordingControl(
          recorderController: _recorderController,
          playerController: _playerController,
          hasRecording: _hasRecording,
          onStartRecording: _startRecording,
          onStopRecording: _stopRecording,
          onCancelRecording: _cancelRecording,
          onTogglePlayback: _togglePlayback,
          onResetRecording: _resetRecording,
        ),
      ],
    );
  }
}

// Practice tag component
class SpeakingPracticeTag extends StatelessWidget {
  const SpeakingPracticeTag({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFE9556A).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.mic,
                color: Color(0xFFE9556A),
                size: 16,
              ),
              const SizedBox(width: 4),
              const Text(
                'Practice',
                style: TextStyle(
                  color: Color(0xFFE9556A),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Instruction bubble component
class SpeakingInstructionBubble extends StatelessWidget {
  final String instruction;

  const SpeakingInstructionBubble({super.key, required this.instruction});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFE3E8EF),
            borderRadius: BorderRadius.circular(44),
          ),
          child: const Icon(
            Icons.person,
            color: Color(0xFF7F8EA4),
            size: 24,
          ),
        ),
        const SizedBox(width: 8),

        // Message bubble
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE3E8EF)),
            ),
            child: Text(
              instruction,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF0D121C),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Audio player card component
class SpeakingAudioCard extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPlayPressed;

  const SpeakingAudioCard({
    super.key,
    required this.isPlaying,
    required this.onPlayPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3E8EF)),
      ),
      child: Row(
        children: [
          // Play button
          GestureDetector(
            onTap: onPlayPressed,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FB),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE3E8EF)),
              ),
              child: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                color: const Color(0xFF554FF0),
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Progress bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCDD5DF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.6, // 60% progress
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF554FF0),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '00:46',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF7F8EA4),
                      ),
                    ),
                    const Text(
                      '-00:34',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF7F8EA4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Recording control component
class SpeakingRecordingControl extends StatelessWidget {
  final RecorderController recorderController;
  final PlayerController? playerController;
  final bool hasRecording;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;
  final VoidCallback onCancelRecording;
  final VoidCallback onTogglePlayback;
  final VoidCallback onResetRecording;

  const SpeakingRecordingControl({
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
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
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
          decoration: BoxDecoration(
            color: const Color(0xFFEBEAFD),
            borderRadius: BorderRadius.circular(1000),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.mic, color: Color(0xFF554FF0), size: 24),
              SizedBox(width: 10),
              Text(
                'Tap to speak',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF554FF0),
                ),
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
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2F6),
                borderRadius: BorderRadius.circular(1000),
              ),
              child: const Icon(
                Icons.close,
                color: Color(0xFF7F8EA4),
                size: 24,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            height: 54,
            padding: const EdgeInsets.only(left: 16, right: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEBEAFD),
              borderRadius: BorderRadius.circular(1000),
            ),
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
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF554FF0),
                      ),
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
                      decoration: BoxDecoration(
                        color: const Color(0xFF554FF0),
                        borderRadius: BorderRadius.circular(1000),
                      ),
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
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
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4B4B),
                        borderRadius: BorderRadius.circular(1000),
                      ),
                      child: const Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1CB0F6).withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    iconSize: 40,
                    icon: Icon(
                      isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: const Color(0xFF1CB0F6),
                    ),
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
                      decoration: BoxDecoration(
                        color: const Color(0xFF58CC02),
                        borderRadius: BorderRadius.circular(1000),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
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
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C3E50),
                      ),
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
                          overlayColor: const Color(0xFF1CB0F6).withOpacity(0.2),
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
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF5D7285),
                      ),
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
