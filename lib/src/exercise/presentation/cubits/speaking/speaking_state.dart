part of '../../../exercise.dart';

enum SpeakingStatus { initial, loading, success, failure }

enum PermissionStatus { unknown, granted, denied, permanentlyDenied }

enum SpeakingInputMode { recording, text }

enum SpeakingRecordingState { idle, recording, paused, playing, stopped }

@freezed
sealed class SpeakingState with _$SpeakingState {
  const factory SpeakingState({
    @Default(SpeakingStatus.initial) SpeakingStatus status,
    @Default(QuestionEntity()) QuestionEntity question,
    @Default(SpeakingInputMode.recording) SpeakingInputMode inputMode,
    @Default(SpeakingRecordingState.idle) SpeakingRecordingState recordingState,
    @Default(PermissionStatus.unknown) PermissionStatus permissionStatus,
    @Default('') String textInput,
    @Default(0) int characterCount,
    String? audioFilePath,
    String? errorMessage,
    @Default(Duration.zero) Duration recordingDuration,
    @Default(false) bool isRecording,
    @Default(false) bool isPlaying,
    @Default(false) bool isPaused,
  }) = _SpeakingState;

  factory SpeakingState.initial() => const SpeakingState();
}
