part of '../../../exercise.dart';

@lazySingleton
class SpeakingCubit extends Cubit<SpeakingState> {
  SpeakingCubit() : super(SpeakingState.initial());

  RecorderController? _recorderController;
  PlayerController? _playerController;
  Timer? _recordingTimer;
  String? _audioPath;

  @override
  Future<void> close() {
    _recordingTimer?.cancel();
    _recorderController?.dispose();
    _playerController?.dispose();
    return super.close();
  }

  void initializeQuestion(QuestionEntity question) {
    emit(state.copyWith(question: question));
  }

  // Toggle between recording and text input modes
  void toggleInputMode() {
    final newMode = state.inputMode == SpeakingInputMode.recording
        ? SpeakingInputMode.text
        : SpeakingInputMode.recording;

    emit(state.copyWith(inputMode: newMode));
  }

  // Initialize recording controller and request permissions
  Future<bool> _initializeRecorder() async {
    if (_recorderController != null) return true;

    try {
      // Request microphone permission
      final permissionStatus = await Permission.microphone.request();

      // Update state with current permission status
      emit(state.copyWith(microphonePermission: permissionStatus));

      if (permissionStatus.isGranted) {
        // Permission granted - initialize recorder
        _recorderController = RecorderController()
          ..androidEncoder = AndroidEncoder.aac
          ..androidOutputFormat = AndroidOutputFormat.mpeg4
          ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
          ..sampleRate = 44100;

        return true;
      } else if (permissionStatus.isPermanentlyDenied) {
        // Permission permanently denied
        emit(state.copyWith(
          status: SpeakingStatus.failure,
          errorMessage: 'Microphone permission is permanently denied. Please enable it in app settings.',
        ));
        return false;
      } else if (permissionStatus.isDenied) {
        // Permission denied
        emit(state.copyWith(
          status: SpeakingStatus.failure,
          errorMessage: 'Microphone permission is required to record audio.',
        ));
        return false;
      } else if (permissionStatus.isRestricted) {
        // Permission restricted (iOS specific)
        emit(state.copyWith(
          status: SpeakingStatus.failure,
          errorMessage: 'Microphone access is restricted on this device.',
        ));
        return false;
      } else {
        // Other cases (limited, provisional, etc)
        emit(state.copyWith(
          status: SpeakingStatus.failure,
          errorMessage: 'Unable to access microphone. Please check your device settings.',
        ));
        return false;
      }
    } catch (e) {
      emit(state.copyWith(
        status: SpeakingStatus.failure,
        errorMessage: 'Failed to initialize recorder: ${e.toString()}',
      ));
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

      emit(state.copyWith(
        status: SpeakingStatus.initial,
        recordingState: SpeakingRecordingState.recording,
        isRecording: true,
        recordingDuration: Duration.zero,
        errorMessage: null,
      ));

      // Start timer to track recording duration
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        final newDuration = Duration(seconds: timer.tick);
        emit(state.copyWith(recordingDuration: newDuration));

        // Auto-stop if max duration reached
        if (state.question.maxDuration > 0 &&
            newDuration.inSeconds >= state.question.maxDuration) {
          stopRecording();
        }
      });
    } catch (e) {
      emit(state.copyWith(
        status: SpeakingStatus.failure,
        errorMessage: 'Failed to start recording: ${e.toString()}',
      ));
    }
  }

  // Stop recording
  Future<void> stopRecording() async {
    _recordingTimer?.cancel();

    if (_recorderController == null) return;

    try {
      final path = await _recorderController!.stop();

      emit(state.copyWith(
        recordingState: SpeakingRecordingState.stopped,
        isRecording: false,
        audioFilePath: path ?? _audioPath,
      ));
    } catch (e) {
      emit(state.copyWith(status: SpeakingStatus.failure));
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
        emit(state.copyWith(
          isPlaying: false,
          isPaused: true,
        ));
      } else {
        // Start or resume playing
        await _playerController!.preparePlayer(
          path: state.audioFilePath!,
          shouldExtractWaveform: true,
        );

        await _playerController!.startPlayer();

        emit(state.copyWith(
          recordingState: SpeakingRecordingState.playing,
          isPlaying: true,
          isPaused: false,
        ));

        // Listen for playback completion
        _playerController!.onCompletion.listen((_) {
          emit(state.copyWith(
            isPlaying: false,
            isPaused: false,
            recordingState: SpeakingRecordingState.stopped,
          ));
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
      emit(state.copyWith(
        isPlaying: false,
        isPaused: true,
      ));
    } catch (e) {
      emit(state.copyWith(status: SpeakingStatus.failure));
    }
  }

  // Update text input
  void updateTextInput(String text) {
    final maxChars = state.question.maxCharacter;
    final trimmedText = maxChars > 0 && text.length > maxChars
        ? text.substring(0, maxChars)
        : text;

    emit(state.copyWith(
      textInput: trimmedText,
      characterCount: trimmedText.length,
    ));
  }

  // Cancel recording and reset
  void cancelRecording() {
    _recordingTimer?.cancel();
    _recorderController?.stop();

    emit(state.copyWith(
      recordingState: SpeakingRecordingState.idle,
      isRecording: false,
      isPlaying: false,
      isPaused: false,
      audioFilePath: null,
      recordingDuration: Duration.zero,
    ));
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

  // Reset to initial state
  void reset() {
    _recordingTimer?.cancel();
    _recorderController?.dispose();
    _playerController?.dispose();
    _recorderController = null;
    _playerController = null;
    _audioPath = null;

    emit(SpeakingState.initial());
  }
}
