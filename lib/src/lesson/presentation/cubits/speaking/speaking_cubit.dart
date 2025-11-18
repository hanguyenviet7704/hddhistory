part of '../../../lesson.dart';

@lazySingleton
class SpeakingCubit extends Cubit<SpeakingState> with CubitUseCaseHandlerMixin<SpeakingState> {
  final SendVoiceFeedbackStreamUseCase _sendVoiceFeedbackStreamUseCase;
  final UploadCubit _uploadCubit;
  final LocaleCubit _localeCubit;

  SpeakingCubit(
    this._sendVoiceFeedbackStreamUseCase,
    this._uploadCubit,
    this._localeCubit,
  ) : super(SpeakingState.initial());

  Stream<Uint8List> _voiceFeedbackStream = Stream.empty();
  Stream<Uint8List> get voiceFeedbackStream => _voiceFeedbackStream;

  // Reset to initial state
  void reset() => emit(SpeakingState.initial());
  void setQuestion(QuestionEntity question) => emit(state.copyWith(question: question));
  void setErrorMessage(String? message) => emit(state.copyWith(errorMessage: message));

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
      ),
    );
  }

  void startRecordingSession() {
    if (state.recordingState != SpeakingRecordingState.idle) return;

    final initialDuration = state.question.maxDuration > 0 ? Duration(seconds: state.question.maxDuration) : Duration.zero;

    emit(
      state.copyWith(
        status: SpeakingStatus.initial,
        recordingState: SpeakingRecordingState.recording,
        recordingDuration: initialDuration,
        errorMessage: null,
        audioFilePath: null,
      ),
    );
  }

  void updateRecordingDuration(Duration duration) => emit(state.copyWith(recordingDuration: duration));
  void pauseRecordingSession() => emit(state.copyWith(recordingState: SpeakingRecordingState.paused));
  void resumeRecordingSession() => emit(state.copyWith(recordingState: SpeakingRecordingState.recording));
  void finishRecordingSession(String path) => emit(state.copyWith(recordingState: SpeakingRecordingState.stopped, audioFilePath: path));
  void cancelRecordingSession() => emit(state.copyWith(recordingState: SpeakingRecordingState.idle, audioFilePath: null, recordingDuration: Duration.zero));
  void updateMicrophonePermission(PermissionStatus status) => emit(state.copyWith(microphonePermission: status));

  // Submit answer (recording or text)
  Future<void> submitAnswer() async {
    if (state.inputMode == SpeakingInputMode.recording) {
      if (state.audioFilePath == null) return;
      emit(state.copyWith(status: SpeakingStatus.loading));
      uploadAudioFile(state.audioFilePath!);
      emit(state.copyWith(status: SpeakingStatus.success));
      return;
    }

    if (state.textInput.isNotEmpty) {
      emit(state.copyWith(status: SpeakingStatus.loading));
      sendVoiceFeedback();
      emit(state.copyWith(status: SpeakingStatus.success));
    }
  }

  void uploadAudioFile(String filePath) async {
    _uploadCubit.uploadFile(
      UploadFileParams(
        file: MultipartFile.fromFileSync(filePath),
        key: DateTime.now().millisecondsSinceEpoch.toString(),
        prefix: 'audio_',
        folder: 'user_lesson',
      ),
      onSuccess: (result) {
        emit(state.copyWith(status: SpeakingStatus.success));
        sendVoiceFeedback(url: result.url);
      },
      onFailure: (error) {
        emit(state.copyWith(status: SpeakingStatus.failure, errorMessage: error));
      },
    );
  }

  void sendVoiceFeedback({String? url}) async {
    LocaleType localeType = _localeCubit.state;
    String? answerText = state.inputMode == SpeakingInputMode.recording ? null : state.textInput;
    String? audioUrl = state.inputMode == SpeakingInputMode.recording ? url : null;
    await runUseCase<ResponseBody>(
      usecase: () => _sendVoiceFeedbackStreamUseCase.call(
        VoiceFeedbackRequest(
          inputType: state.inputMode == SpeakingInputMode.recording ? 'audio' : 'text',
          answerText: answerText,
          audioUrl: audioUrl,
          knowledge: 'Machine Learning (học máy) là một nhánh của trí tuệ nhân tạo (AI), cho phép máy tính tự học từ dữ liệu mà không cần lập trình rõ ràng',
          originLanguage: localeType.languageAISupport,
          languageFeedback: localeType.languageAISupport,
        ),
      ),
      onSuccess: (result) {
        _voiceFeedbackStream = result.stream;
        _voiceFeedbackStream
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen(
              (line) {
                if (line.startsWith("data:")) {
                  LogDev.one("EVENT → ${line.substring(5).trim()}");
                }
              },
              onDone: () {
                LogDev.one("✔ Stream ended");
              },
              onError: (err) {
                LogDev.one("❌ Stream error: $err");
              },
            );
        emit(state.copyWith(status: SpeakingStatus.success));
      },
      onFailure: (error) {
        emit(state.copyWith(status: SpeakingStatus.failure, errorMessage: error));
      },
    );
  }

  // Toggle explanation visibility
  void toggleExplanation() => emit(state.copyWith(showExplanation: !state.showExplanation));

  int pointCalculation() {
    return 100;
  }
}
