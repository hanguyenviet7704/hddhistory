part of '../../lesson.dart';

@freezed
abstract class VoiceFeedbackRequest with _$VoiceFeedbackRequest {
  const factory VoiceFeedbackRequest({
    @JsonKey(name: 'input_type') required String inputType,
    @JsonKey(name: 'answer_text', includeIfNull: false) String? answerText,
    @JsonKey(name: 'audio_url', includeIfNull: false) String? audioUrl,
    @JsonKey(name: 'knowledge') required String knowledge,
    @JsonKey(name: 'origin_language') required String originLanguage,
    @JsonKey(name: 'language_feedback') required String languageFeedback,
  }) = _VoiceFeedbackRequest;

  factory VoiceFeedbackRequest.fromJson(Map<String, dynamic> json) => _$VoiceFeedbackRequestFromJson(json);
}

@lazySingleton
class SendVoiceFeedbackStreamUseCase implements BaseUseCase<VoiceFeedbackRequest, ResponseBody> {
  final ILessonRepository _repository;

  SendVoiceFeedbackStreamUseCase(this._repository);

  @override
  TaskEither<AppException, ResponseBody> call(VoiceFeedbackRequest params) {
    return _repository.sendVoiceFeedbackStream(params);
  }
}
