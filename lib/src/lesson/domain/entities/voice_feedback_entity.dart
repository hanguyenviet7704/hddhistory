part of '../../lesson.dart';

@freezed
abstract class VoiceFeedbackEntity with _$VoiceFeedbackEntity {
  const factory VoiceFeedbackEntity({
    @Default('') String feedbackText,
    @Default(0.0) double timeDownload,
    @Default(0.0) double timeWhisper,
    @Default(0.0) double timeGpt,
    @Default('') String textStt,
  }) = _VoiceFeedbackEntity;

  factory VoiceFeedbackEntity.fromJson(Map<String, dynamic> json) => _$VoiceFeedbackEntityFromJson(json);
}
