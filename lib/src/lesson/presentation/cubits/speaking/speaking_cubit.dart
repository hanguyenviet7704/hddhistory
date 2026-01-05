part of '../../../lesson.dart';

@lazySingleton
class SpeakingCubit extends Cubit<SpeakingState> with CubitUseCaseHandlerMixin<SpeakingState> {
  final SendVoiceFeedbackStreamUseCase _sendVoiceFeedbackStreamUseCase;
  final SendScoreRecordUseCase _sendScoreRecordUseCase;
  final UploadCubit _uploadCubit;
  final LocaleCubit _localeCubit;

  SpeakingCubit(
    this._sendVoiceFeedbackStreamUseCase,
    this._sendScoreRecordUseCase,
    this._uploadCubit,
    this._localeCubit,
  ) : super(SpeakingState.initial());

  Stream<Uint8List> _voiceFeedbackStream = Stream.empty();
  Stream<Uint8List> get voiceFeedbackStream => _voiceFeedbackStream;
  StreamSubscription<String>? _streamSubscription;
  String _feedbackStream = '';
  double _questionScore = 0;

  // Reset to initial state
  void reset() {
    emit(SpeakingState.initial());
    _questionScore = 0;
  }

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

  Future<void> startRecordingSession() async {
    if (state.recordingState != SpeakingRecordingState.idle) return;

    final hasPermission = await _ensureMicrophonePermission();
    if (!hasPermission) return;

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
  Future<bool> _ensureMicrophonePermission() async {
    var status = await Permission.microphone.status;

    // If already decided (granted or permanently denied), update state and short-circuit
    if (status.isGranted) {
      updateMicrophonePermission(status);
      return true;
    }

    if (status.isPermanentlyDenied || status.isRestricted) {
      updateMicrophonePermission(status);
      setErrorMessage(_permissionMessage(status));
      return false;
    }

    // Request runtime permission
    status = await Permission.microphone.request();
    updateMicrophonePermission(status);

    if (status.isGranted) {
      setErrorMessage(null);
      return true;
    }

    setErrorMessage(_permissionMessage(status));
    return false;
  }

  String _permissionMessage(PermissionStatus status) {
    if (status.isPermanentlyDenied) {
      return 'Microphone permission is permanently denied. Please enable it in app settings.';
    }
    if (status.isRestricted) {
      return 'Microphone access is restricted on this device.';
    }
    return 'Microphone permission is required to record audio.';
  }

  // Submit answer (recording or text)
  Future<void> submitAnswer() async {
    if (state.inputMode == SpeakingInputMode.recording) {
      emit(state.copyWith(status: SpeakingStatus.success));
      if (state.audioFilePath == null) return;
      emit(state.copyWith(status: SpeakingStatus.loading));
      uploadAudioFile(state.audioFilePath!);
      return;
    }

    if (state.textInput.isEmpty) return;
    emit(state.copyWith(status: SpeakingStatus.success));
    AppDI.injector.get<RoleplayCubit>().setExerciseRecordAnswer(
      questionId: state.question.id,
      textAnswer: state.textInput,
    );
    getVoiceFeedback();
    getScoreRecord();
    emit(state.copyWith(status: SpeakingStatus.loading));
  }

  void uploadAudioFile(String filePath) async {
    _uploadCubit.uploadFile(
      UploadFileParams(
        file: MultipartFile.fromFileSync(filePath),
        key: filePath.fileNameFromPath,
        prefix: 'audio_',
        folder: 'user_lesson',
      ),
      onSuccess: (result) {
        AppDI.injector.get<RoleplayCubit>().setExerciseRecordAnswer(
          questionId: state.question.id,
          recordPath: result.url,
        );
        getVoiceFeedback(url: result.url);
        getScoreRecord(audioUrl: result.url);
      },
      onFailure: (error) {
        emit(state.copyWith(status: SpeakingStatus.failure, errorMessage: error));
      },
    );
  }

  void getScoreRecord({String? audioUrl}) async {
    final criteria = <String, int>{};
    for (final scoringCriteria in state.question.scoringCriteria) {
      criteria[scoringCriteria.criteria.text] = scoringCriteria.maxScore;
    }

    final theory = <String, String>{};
    final keypoint = state.question.keypoint;
    if (keypoint.title.text.isNotEmpty) {
      theory[keypoint.title.text] = keypoint.description.text;
    }

    final isAudioMode = state.inputMode == SpeakingInputMode.recording;

    final body = <String, dynamic>{
      'question': state.question.speechBubble.text,
      'criteria': criteria,
      'theory': theory,
      'user_answer_type': isAudioMode ? 'audio' : 'text',
      if (!isAudioMode) 'answer_text': state.textInput,
      if (isAudioMode && audioUrl != null) 'audio_url': audioUrl,
    };

    await runUseCase<VoiceScoreEntity>(
      usecase: () => _sendScoreRecordUseCase(body),
      buildLoadingState: () => state.copyWith(status: SpeakingStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(status: SpeakingStatus.failure, errorMessage: error));
      },
      onSuccess: (result) => _questionScore = result.score,
    );
  }

  void getVoiceFeedback({String? url}) async {
    await _streamSubscription?.cancel();
    _feedbackStream = '';
    emit(state.copyWith(goodPoints: const [], improvementPoints: const []));

    AppLocale localeType = _localeCubit.state;
    String? answerText = state.inputMode == SpeakingInputMode.recording ? null : state.textInput;
    String? audioUrl = state.inputMode == SpeakingInputMode.recording ? url : null;
    String knowledge = state.question.scoringCriteria.map((e) => e.criteria.text).join(' \n');
    await runUseCase<ResponseBody>(
      usecase: () => _sendVoiceFeedbackStreamUseCase.call(
        VoiceFeedbackRequest(
          inputType: state.inputMode == SpeakingInputMode.recording ? 'audio' : 'text',
          answerText: answerText,
          audioUrl: audioUrl,
          knowledge: knowledge,
          originLanguage: localeType.languageAISupport,
          languageFeedback: localeType.languageAISupport,
        ),
      ),
      onSuccess: (result) {
        _voiceFeedbackStream = result.stream;

        _streamSubscription = _voiceFeedbackStream
            .cast<List<int>>()
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen(
              (line) {
                if (!line.startsWith("data:")) return;

                final payload = _extractSsePayload(line);
                if (payload == '[DONE]') {
                  setPoints();
                  return;
                }

                if (payload.isEmpty) {
                  return;
                }

                _feedbackStream += payload;
                LogDev.one("SPEAKING STREAM → $payload");
                setPoints();
              },
              onDone: () {
                LogDev.one("✔ Stream ended");
                if (_feedbackStream.isNotEmpty) {
                  setPoints();
                }
                // emit(state.copyWith(status: SpeakingStatus.success));
              },
              onError: (err) {
                LogDev.one("❌ Stream error: $err");
                // emit(state.copyWith(status: SpeakingStatus.failure, errorMessage: err.toString()));
              },
            );
      },
      onFailure: (error) {
        emit(state.copyWith(status: SpeakingStatus.failure, errorMessage: error));
      },
    );
  }

  void setPoints() {
    final rawFeedback = _feedbackStream.replaceAll('[DONE]', '').trim();
    if (rawFeedback.isEmpty) return;

    final goodHeaderRegex = RegExp(r'🟢\s*\*\*?.*?\*\*?', dotAll: true, caseSensitive: false);
    final improvementHeaderRegex = RegExp(r'🔵\s*\*\*?.*?\*\*?', dotAll: true, caseSensitive: false);

    final goodMatch = goodHeaderRegex.firstMatch(rawFeedback);
    final improvementMatch = improvementHeaderRegex.firstMatch(rawFeedback);

    String goodSection = '';
    String improvementSection = '';

    if (goodMatch != null) {
      final endIndex = improvementMatch != null ? improvementMatch.start : rawFeedback.length;
      goodSection = rawFeedback.substring(goodMatch.end, endIndex);
    }

    if (improvementMatch != null) {
      improvementSection = rawFeedback.substring(improvementMatch.end);
    }

    final goodPoints = _extractPoints(goodSection);
    final improvementPoints = _extractPoints(improvementSection);

    if (goodPoints.isEmpty && improvementPoints.isEmpty) return;

    emit(
      state.copyWith(
        goodPoints: goodPoints,
        improvementPoints: improvementPoints,
      ),
    );
  }

  List<String> _extractPoints(String section) {
    if (section.trim().isEmpty) return const [];
    final cleaned = section.replaceAll(RegExp(r'\s+'), ' ').trim();
    final parts = cleaned.split(RegExp(r'[-•]\s+')).skip(1).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    return parts;
  }

  String _extractSsePayload(String line) {
    var payload = line.replaceAll('\r', '');
    const prefix = 'data:';
    while (payload.startsWith(prefix)) {
      payload = payload.substring(prefix.length);
      if (payload.startsWith(' ')) {
        payload = payload.substring(1);
      }
    }
    return payload.trimRight();
  }

  // Toggle explanation visibility
  void toggleExplanation() => emit(state.copyWith(showExplanation: !state.showExplanation));

  int pointCalculation() => _questionScore.toInt();

  @override
  Future<void> close() async {
    await _streamSubscription?.cancel();
    return super.close();
  }

  ExerciseResultEntity toExerciseResult() {
    final question = state.question;
    final recordAnswer = AnswerEntity(
      record: state.audioFilePath ?? '',
      review: state.textInput,
    );

    return ExerciseResultEntity(
      exerciseId: question.id.toString(),
      type: question.type,
      form: question.form,
      recordAnswer: recordAnswer,
    );
  }

  void applyExerciseResult(ExerciseResultEntity result) {
    final question = state.question;
    if (question.id == 0) return;

    final record = result.recordAnswer.record;
    final review = result.recordAnswer.review;
    final inputMode = record.isNotEmpty ? SpeakingInputMode.recording : SpeakingInputMode.text;

    emit(
      state.copyWith(
        inputMode: inputMode,
        audioFilePath: record.isNotEmpty ? record : null,
        textInput: review,
      ),
    );
  }
}
