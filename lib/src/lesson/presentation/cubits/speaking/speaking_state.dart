part of '../../../lesson.dart';

enum SpeakingStatus { initial, loading, success, failure }

enum SpeakingInputMode { recording, text }

enum SpeakingRecordingState { idle, recording, paused, playing, stopped }

@freezed
sealed class SpeakingState with _$SpeakingState {
  const factory SpeakingState({
    @Default(SpeakingStatus.initial) SpeakingStatus status,
    @Default(QuestionEntity()) QuestionEntity question,
    @Default(SpeakingInputMode.recording) SpeakingInputMode inputMode,
    @Default(SpeakingRecordingState.idle) SpeakingRecordingState recordingState,
    PermissionStatus? microphonePermission,
    @Default('') String textInput,
    @Default(0) int characterCount,
    String? audioFilePath,
    String? errorMessage,
    @Default(Duration.zero) Duration recordingDuration,
    @Default(false) bool isRecording,
    @Default(false) bool isPlaying,
    @Default(false) bool isPaused,
    @Default(false) bool showExplanation,
  }) = _SpeakingState;

  factory SpeakingState.initial() => const SpeakingState();
}

extension SpeakingStateExtension on SpeakingState {
  int get currentChars => textInput.length;
  int get maxChars => question.maxCharacter;
  double get recordingProgress {
    if (question.maxDuration <= 0) return 0;
    return recordingDuration.inSeconds / question.maxDuration;
  }
}