part of '../../../lesson.dart';

enum SpeakingStatus { initial, loading, success, failure }

enum SpeakingInputMode { recording, text }

enum SpeakingRecordingState { idle, recording, paused, playing, stopped }

@freezed
sealed class SpeakingState with _$SpeakingState {
  const factory SpeakingState({
    //* Speaking Cubit initial data
    @Default(SpeakingStatus.initial) SpeakingStatus status,
    @Default(QuestionEntity()) QuestionEntity question,
    String? errorMessage,
    
    //* Speaking Cubit input data
    PermissionStatus? microphonePermission,
    @Default(SpeakingInputMode.recording) SpeakingInputMode inputMode,
    @Default(SpeakingRecordingState.idle) SpeakingRecordingState recordingState,
    @Default('') String textInput,
    String? audioFilePath,
    @Default(Duration.zero) Duration recordingDuration,
    @Default(false) bool showExplanation,
    @Default('') String goodPoints,
    @Default('') String improvementPoints,
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
