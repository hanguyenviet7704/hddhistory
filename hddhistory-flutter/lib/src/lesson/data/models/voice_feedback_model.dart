part of '../../lesson.dart';

@freezed
abstract class VoiceFeedbackModel with _$VoiceFeedbackModel {
  const factory VoiceFeedbackModel({
    @JsonKey(name: 'feedback_text') @Default('') String feedbackText,
    @JsonKey(name: 'time_download', fromJson: _doubleFromJson) @Default(0.0) double timeDownload,
    @JsonKey(name: 'time_whisper', fromJson: _doubleFromJson) @Default(0.0) double timeWhisper,
    @JsonKey(name: 'time_gpt', fromJson: _doubleFromJson) @Default(0.0) double timeGpt,
    @JsonKey(name: 'text_stt') @Default('') String textStt,
  }) = _VoiceFeedbackModel;

  factory VoiceFeedbackModel.fromJson(Map<String, dynamic> json) => _$VoiceFeedbackModelFromJson(json);
}

double _doubleFromJson(num? value) => (value ?? 0).toDouble();

extension VoiceFeedbackModelExtension on VoiceFeedbackModel {
  VoiceFeedbackEntity toEntity() => VoiceFeedbackEntity(
    feedbackText: feedbackText,
    timeDownload: timeDownload,
    timeWhisper: timeWhisper,
    timeGpt: timeGpt,
    textStt: textStt,
  );
}
