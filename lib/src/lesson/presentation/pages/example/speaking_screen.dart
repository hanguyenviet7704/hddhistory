part of '../../../lesson.dart';

class SpeakingScreen extends StatefulWidget {
  const SpeakingScreen({super.key});

  @override
  State<SpeakingScreen> createState() => _SpeakingScreenState();
}

class _SpeakingScreenState extends State<SpeakingScreen> {
  late RecorderController _recorderController;
  PlayerController? _playerController;
  String? _recordingPath;
  bool _hasRecording = false;

  @override
  void initState() {
    super.initState();
    _initializeRecorder();
  }

  Future<void> _initializeRecorder() async {
    _recorderController = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
      ..sampleRate = 44100;
    await _checkPermission();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SpeakingHeader(onBack: () => Navigator.of(context).pop()),
              const SizedBox(height: 32),
              const InstructionCard(title: 'Speak this sentence', subtitle: 'The cat drinks milk', onPlayAudio: null),
              const Spacer(),
              RecordingControl(
                recorderController: _recorderController,
                playerController: _playerController,
                hasRecording: _hasRecording,
                onStartRecording: _startRecording,
                onStopRecording: _stopRecording,
                onCancelRecording: _cancelRecording,
                onTogglePlayback: _togglePlayback,
                onResetRecording: _resetRecording,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
