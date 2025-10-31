part of '../../../lesson.dart';

@lazySingleton
class SpeakingCubit extends Cubit<SpeakingState> {
  SpeakingCubit() : super(SpeakingState.initial());

  RecorderController? _recorderController;
  PlayerController? _playerController;
  Timer? _recordingTimer;
  String _audioPath = '';

  // Expose recorder controller for waveform visualization
  RecorderController? get recorderController => _recorderController;

  // Expose player controller for waveform visualization after recording stops
  PlayerController? get playerController => _playerController;

  @override
  Future<void> close() {
    _recordingTimer?.cancel();
    _recorderController?.dispose();
    _playerController?.dispose();
    return super.close();
  }

  // Reset to initial state
  void reset() {
    _recordingTimer?.cancel();
    _recorderController?.dispose();
    _playerController?.dispose();
    _recorderController = null;
    _playerController = null;
    _audioPath = '';

    emit(SpeakingState.initial());
  }

  void loadQuestion(QuestionEntity question) {
    emit(state.copyWith(question: question));
  }

  // Toggle between recording and text input modes
  void toggleInputMode() {
    final newMode = state.inputMode == SpeakingInputMode.recording ? SpeakingInputMode.text : SpeakingInputMode.recording;

    emit(state.copyWith(inputMode: newMode));
  }

  // Update text input
  void updateTextInput(String text) {
    final maxChars = state.question.maxCharacter;
    final trimmedText = maxChars > 0 && text.length > maxChars ? text.substring(0, maxChars) : text;

    emit(
      state.copyWith(
        textInput: trimmedText,
        characterCount: trimmedText.length,
      ),
    );
  }

  // Initialize recording controller and request permissions
  Future<bool> _initializeRecorder() async {
    if (_recorderController != null) return true;

    try {
      // First check the current permission status
      var permissionStatus = await Permission.microphone.status;

      // Update state with current permission status
      emit(state.copyWith(microphonePermission: permissionStatus));

      // If not granted, request permission
      if (!permissionStatus.isGranted) {
        permissionStatus = await Permission.microphone.request();
        // Update state with new permission status after request
        emit(state.copyWith(microphonePermission: permissionStatus));
      }

      if (permissionStatus.isGranted) {
        // Permission granted - initialize recorder
        _recorderController = RecorderController()
          ..androidEncoder = AndroidEncoder.aac
          ..androidOutputFormat = AndroidOutputFormat.mpeg4
          ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
          ..sampleRate = 44100
          ..updateFrequency = const Duration(milliseconds: 100);

        return true;
      }

      if (permissionStatus.isPermanentlyDenied) {
        // Permission permanently denied - guide user to settings
        emit(
          state.copyWith(
            status: SpeakingStatus.failure,
            errorMessage: 'Microphone permission is permanently denied. Please enable it in app settings.',
          ),
        );
        return false;
      }

      if (permissionStatus.isDenied) {
        // Permission denied
        emit(
          state.copyWith(
            status: SpeakingStatus.failure,
            errorMessage: 'Microphone permission is required to record audio.',
          ),
        );
        return false;
      }

      if (permissionStatus.isRestricted) {
        // Permission restricted (iOS specific)
        emit(
          state.copyWith(
            status: SpeakingStatus.failure,
            errorMessage: 'Microphone access is restricted on this device.',
          ),
        );
        return false;
      }

      if (permissionStatus.isLimited) {
        // Permission limited (iOS 14+ specific)
        emit(
          state.copyWith(
            status: SpeakingStatus.failure,
            errorMessage: 'Microphone access is limited. Please grant full access in settings.',
          ),
        );
        return false;
      }
      // Other cases (provisional, etc)
      emit(
        state.copyWith(
          status: SpeakingStatus.failure,
          errorMessage: 'Unable to access microphone. Please check your device settings.',
        ),
      );
      return false;
    } catch (e) {
      emit(
        state.copyWith(
          status: SpeakingStatus.failure,
          errorMessage: 'Failed to initialize recorder: ${e.toString()}',
        ),
      );
      return false;
    }
  }

  // Start recording audio
  Future<void> startRecording() async {
    final initialized = await _initializeRecorder();

    if (!initialized || _recorderController == null) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      _audioPath = '${directory.path}/speaking_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorderController!.record(path: _audioPath);

      emit(
        state.copyWith(
          status: SpeakingStatus.initial,
          recordingState: SpeakingRecordingState.recording,
          isRecording: true,
          recordingDuration: Duration.zero,
          errorMessage: null,
          audioFilePath: _audioPath,
        ),
      );

      // Start timer to track recording duration
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        final newDuration = Duration(seconds: timer.tick);
        emit(state.copyWith(recordingDuration: newDuration));

        // Auto-stop if max duration reached
        if (state.question.maxDuration > 0 && newDuration.inSeconds >= state.question.maxDuration) {
          stopRecording();
        }
      });
    } catch (e) {
      emit(
        state.copyWith(
          status: SpeakingStatus.failure,
          errorMessage: 'Failed to start recording: ${e.toString()}',
        ),
      );
    }
  }

  // Pause recording
  Future<void> pauseRecording() async {
    _recorderController?.pause();
    _recordingTimer?.cancel();
    emit(state.copyWith(recordingState: SpeakingRecordingState.paused));
  }

  // Resume recording
  Future<void> resumeRecording() async {
    _recorderController?.record();

    // Continue timer from current duration
    final pausedDuration = state.recordingDuration;
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final newDuration = pausedDuration + Duration(seconds: timer.tick);
      emit(state.copyWith(recordingDuration: newDuration));

      // Auto-stop if max duration reached
      if (state.question.maxDuration > 0 && newDuration.inSeconds >= state.question.maxDuration) {
        stopRecording();
      }
    });
    emit(state.copyWith(recordingState: SpeakingRecordingState.recording));
  }

  // Stop recording
  Future<void> stopRecording() async {
    _recordingTimer?.cancel();

    if (_recorderController == null) return;

    try {
      // Just pause to preserve the waveform visualization
      // The audio file path is already stored in _audioPath
      _recorderController!.pause();

      // Initialize player controller for playback
      await _initializePlayerWithWaveform(_audioPath);

      emit(
        state.copyWith(
          recordingState: SpeakingRecordingState.stopped,
          isRecording: false,
          audioFilePath: _audioPath,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: SpeakingStatus.failure));
    }
  }

  // Initialize player controller with waveform extraction
  Future<void> _initializePlayerWithWaveform(String audioPath) async {
    try {
      // Dispose existing player if any
      _playerController?.dispose();

      // Create new player controller and prepare with waveform extraction
      _playerController = PlayerController();
      await _playerController!.preparePlayer(
        path: audioPath,
        shouldExtractWaveform: true,
      );
    } catch (e) {
      // If waveform extraction fails, just continue without it
      // ignore: avoid_print
      print('Failed to extract waveform: $e');
    }
  }

  // Initialize player controller
  Future<void> _initializePlayer() async {
    if (_playerController != null) return;

    _playerController = PlayerController();
  }

  // Play recorded audio
  Future<void> playRecording() async {
    if (state.audioFilePath == null) return;

    await _initializePlayer();

    if (_playerController == null) return;

    try {
      if (state.isPlaying) {
        // If already playing, pause it
        await _playerController!.pausePlayer();
        emit(
          state.copyWith(
            isPlaying: false,
            isPaused: true,
          ),
        );
      } else {
        // Start or resume playing
        await _playerController!.preparePlayer(
          path: state.audioFilePath!,
          shouldExtractWaveform: true,
        );

        await _playerController!.startPlayer();

        emit(
          state.copyWith(
            recordingState: SpeakingRecordingState.playing,
            isPlaying: true,
            isPaused: false,
          ),
        );

        // Listen for playback completion
        _playerController!.onCompletion.listen((_) {
          emit(
            state.copyWith(
              isPlaying: false,
              isPaused: false,
              recordingState: SpeakingRecordingState.stopped,
            ),
          );
        });
      }
    } catch (e) {
      emit(state.copyWith(status: SpeakingStatus.failure));
    }
  }

  // Pause playback
  Future<void> pausePlayback() async {
    if (_playerController == null || !state.isPlaying) return;

    try {
      await _playerController!.pausePlayer();
      emit(
        state.copyWith(
          isPlaying: false,
          isPaused: true,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: SpeakingStatus.failure));
    }
  }

  // Cancel recording and reset
  void cancelRecording() {
    _recordingTimer?.cancel();
    _recorderController?.stop();

    emit(
      state.copyWith(
        recordingState: SpeakingRecordingState.idle,
        isRecording: false,
        isPlaying: false,
        isPaused: false,
        audioFilePath: null,
        recordingDuration: Duration.zero,
      ),
    );
  }

  // Submit answer (recording or text)
  Future<void> submitAnswer() async {
    if (state.inputMode == SpeakingInputMode.recording) {
      if (state.audioFilePath != null) {
        emit(state.copyWith(status: SpeakingStatus.loading));
        // TODO: Implement audio submission logic
        // This will be handled by the parent exercise cubit
        emit(state.copyWith(status: SpeakingStatus.success));
      }
    } else {
      if (state.textInput.isNotEmpty) {
        emit(state.copyWith(status: SpeakingStatus.loading));
        // TODO: Implement text submission logic
        // This will be handled by the parent exercise cubit
        emit(state.copyWith(status: SpeakingStatus.success));
      }
    }
  }

  // Toggle explanation visibility
  void toggleExplanation() {
    emit(state.copyWith(showExplanation: !state.showExplanation));
  }
}
