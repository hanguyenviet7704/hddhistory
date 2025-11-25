part of '../../lesson.dart';

enum LessonVoiceStatus { initial, loading, success, failure }

@freezed
abstract class LessonVoiceState with _$LessonVoiceState {
  const factory LessonVoiceState({
    @Default(LessonVoiceStatus.initial) LessonVoiceStatus status,
    VoiceFeedbackEntity? voiceFeedback,
    @JsonKey(includeFromJson: false, includeToJson: false) ResponseBody? streamResponse,
    String? errorMessage,
  }) = _LessonVoiceState;

  factory LessonVoiceState.initial() => LessonVoiceState();

  factory LessonVoiceState.fromJson(Map<String, dynamic> json) => _$LessonVoiceStateFromJson(json);
}

