part of '../../../lesson.dart';

@lazySingleton
class SpeakingCubit extends Cubit<SpeakingState> {
  final SendVoiceFeedbackStreamUseCase _sendVoiceFeedbackStreamUseCase;
  SpeakingCubit(this._sendVoiceFeedbackStreamUseCase) : super(SpeakingState.initial());

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
      // TODO: Implement audio submission logic
      // This will be handled by the parent exercise cubit
      emit(state.copyWith(status: SpeakingStatus.success));
      return;
    }

    if (state.textInput.isNotEmpty) {
      emit(state.copyWith(status: SpeakingStatus.loading));
      // TODO: Implement text submission logic
      // This will be handled by the parent exercise cubit
      emit(state.copyWith(status: SpeakingStatus.success));
    }
  }

  

  // Toggle explanation visibility
  void toggleExplanation() => emit(state.copyWith(showExplanation: !state.showExplanation));

  int pointCalculation() {
    return 100;
  }
}
