part of '../../../../lesson.dart';

// Active Recording Mode: Cancel + Recording controls + Send
class ActiveRecordingMode extends StatefulWidget {
  const ActiveRecordingMode({super.key});

  @override
  State<ActiveRecordingMode> createState() => _ActiveRecordingModeState();
}

class _ActiveRecordingModeState extends State<ActiveRecordingMode> {
  final AudioRecorder _recorder = AudioRecorder();
  Timer? _recordingTimer;
  String? _currentFilePath;
  late final bool _hasTimeLimit;
  Duration _currentTimerValue = Duration.zero;
  bool _isRecorderActive = false;

  SpeakingCubit get _cubit => context.read<SpeakingCubit>();

  @override
  void initState() {
    super.initState();
    final currentState = _cubit.state;
    _hasTimeLimit = currentState.question.maxDuration > 0;
    _currentTimerValue = currentState.recordingDuration;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _startRecording();
    });
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    unawaited(_recorder.cancel());
    unawaited(_recorder.dispose());
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (_isRecorderActive) return;

    final hasPermission = await _ensurePermission();
    if (!hasPermission) {
      if (mounted) {
        _cubit.cancelRecordingSession();
      }
      return;
    }

    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/speaking_${DateTime.now().millisecondsSinceEpoch}.m4a';
    _currentFilePath = path;

    try {
      const config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 44100,
        bitRate: 128000,
      );
      await _recorder.start(config, path: path);
      _isRecorderActive = true;
      if (!mounted) return;
      _currentTimerValue = _cubit.state.recordingDuration;
      _startTimer();
    } catch (e) {
      _handleRecordingError('Failed to start recording');
      _cubit.cancelRecordingSession();
    }
  }

  Future<bool> _ensurePermission() async {
    var permissionStatus = await Permission.microphone.status;
    if (mounted) {
      _cubit.updateMicrophonePermission(permissionStatus);
    }

    if (!permissionStatus.isGranted) {
      permissionStatus = await Permission.microphone.request();
      if (mounted) {
        _cubit.updateMicrophonePermission(permissionStatus);
      }
    }

    if (permissionStatus.isGranted) {
      return true;
    }

    final message = () {
      if (permissionStatus.isPermanentlyDenied) {
        return 'Microphone permission is permanently denied. Please enable it in app settings.';
      }
      if (permissionStatus.isRestricted) {
        return 'Microphone access is restricted on this device.';
      }
      if (permissionStatus.isLimited) {
        return 'Microphone access is limited. Please grant full access in settings.';
      }
      return 'Microphone permission is required to record audio.';
    }();

    if (mounted) {
      _cubit.setErrorMessage(message);
    }
    EasyLoading.showError(message);
    return false;
  }

  void _startTimer() {
    _recordingTimer?.cancel();
    _currentTimerValue = _cubit.state.recordingDuration;

    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) return;

      if (_hasTimeLimit) {
        final nextValue = _currentTimerValue - const Duration(seconds: 1);
        if (nextValue.inSeconds <= 0) {
          _cubit.updateRecordingDuration(Duration.zero);
          await _stopRecordingSession();
          return;
        }
        _currentTimerValue = nextValue;
        _cubit.updateRecordingDuration(_currentTimerValue);
      } else {
        _currentTimerValue = _currentTimerValue + const Duration(seconds: 1);
        _cubit.updateRecordingDuration(_currentTimerValue);
      }
    });
  }

  Future<void> _pauseRecording() async {
    if (!_isRecorderActive) return;

    try {
      await _recorder.pause();
      _isRecorderActive = false;
      _recordingTimer?.cancel();
      if (mounted) {
        _cubit.pauseRecordingSession();
      }
    } catch (e) {
      _handleRecordingError('Unable to pause recording');
    }
  }

  Future<void> _resumeRecording() async {
    if (_isRecorderActive) return;

    try {
      await _recorder.resume();
      _isRecorderActive = true;
      _startTimer();
      if (mounted) {
        _cubit.resumeRecordingSession();
      }
    } catch (e) {
      _handleRecordingError('Unable to resume recording');
    }
  }

  Future<bool> _stopRecordingSession({bool saveRecording = true}) async {
    _recordingTimer?.cancel();

    try {
      if (!saveRecording) {
        await _recorder.cancel();
        _isRecorderActive = false;
        return true;
      }

      final recordedPath = await _recorder.stop();
      _isRecorderActive = false;
      final resolvedPath = recordedPath ?? _currentFilePath;
      if (resolvedPath == null) {
        _handleRecordingError('Recording file could not be saved');
        return false;
      }
      if (mounted) {
        _cubit.finishRecordingSession(resolvedPath);
      }
      return true;
    } catch (e) {
      _handleRecordingError('Failed to stop recording');
      return false;
    }
  }

  void _handleRecordingError(String message) {
    EasyLoading.showError(message);
    if (mounted) {
      _cubit.setErrorMessage(message);
    }
  }

  Future<void> _handleControlTap() async {
    final recordingState = _cubit.state.recordingState;
    if (recordingState == SpeakingRecordingState.recording) {
      await _pauseRecording();
    } else if (recordingState == SpeakingRecordingState.paused) {
      await _resumeRecording();
    }
  }

  Future<void> _handleCancel() async {
    await _stopRecordingSession(saveRecording: false);
    if (!mounted) return;
    _cubit.cancelRecordingSession();
  }

  Future<void> _handleSubmit() async {
    final currentState = _cubit.state;
    if (currentState.recordingState == SpeakingRecordingState.recording || currentState.recordingState == SpeakingRecordingState.paused) {
      final success = await _stopRecordingSession();
      if (!success) return;
    }

    if (!mounted) return;
    final updatedState = _cubit.state;
    if (updatedState.audioFilePath == null) return;
    await _cubit.submitAnswer();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BlocSelector<SpeakingCubit, SpeakingState, ({bool isRecording, Duration duration})>(
          selector: (state) => (isRecording: state.recordingState == SpeakingRecordingState.recording, duration: state.recordingDuration),
          builder: (context, data) {
            return AppText(
              data.duration.formatDuration,
              style: AppStyle.textBold16.copyWith(color: data.isRecording ? const Color(0xFF554FF0) : const Color(0xFFAAB7CC)),
            );
          },
        ),
        12.verticalSpace,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ModeToggleButton(
              svgIcon: AppAsset.svg.app.icClose,
              backgroundColor: const Color(0xFFEEF2F6),
              iconColor: const Color(0xFF7F8EA4),
              iconSize: 24,
              padding: 12,
              onTap: () => unawaited(_handleCancel()),
            ),
            BlocSelector<SpeakingCubit, SpeakingState, SpeakingRecordingState>(
              selector: (state) => state.recordingState,
              builder: (context, recordingState) {
                return RecordingControlsArea(
                  recordingState: recordingState,
                  onTap: recordingState == SpeakingRecordingState.recording || recordingState == SpeakingRecordingState.paused ? () => unawaited(_handleControlTap()) : null,
                );
              },
            ),
            BlocBuilder<SpeakingCubit, SpeakingState>(
              buildWhen: (previous, current) => previous.audioFilePath != current.audioFilePath || previous.recordingState != current.recordingState,
              builder: (context, state) {
                final canSubmit = state.audioFilePath != null && state.recordingState == SpeakingRecordingState.stopped;
                final isStillRecording = state.recordingState == SpeakingRecordingState.recording || state.recordingState == SpeakingRecordingState.paused;
                final isEnabled = canSubmit || isStillRecording;

                return GestureDetector(
                  onTap: isEnabled ? () => unawaited(_handleSubmit()) : null,
                  child: Container(
                    width: 48.w,
                    height: 48.w,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isEnabled ? const Color(0xFF554FF0) : const Color(0xFF554FF0).withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: SvgPicture.asset(
                      AppAsset.svg.app.icSend,
                      width: 24.w,
                      height: 24.w,
                      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
