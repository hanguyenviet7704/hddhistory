part of '../../lesson.dart';


@freezed
abstract class ScoreRecordRequest with _$ScoreRecordRequest {
  const factory ScoreRecordRequest({
    @JsonKey(name: 'input_type') required String inputType,
    @JsonKey(name: 'answer_text', includeIfNull: false) String? answerText,
    @JsonKey(name: 'audio_url', includeIfNull: false) String? audioUrl,
    @JsonKey(name: 'knowledge') required String knowledge,
    @JsonKey(name: 'origin_language') required String originLanguage,
    @JsonKey(name: 'language_feedback') required String languageFeedback,
  }) = _ScoreRecordRequest;

  factory ScoreRecordRequest.fromJson(Map<String, dynamic> json) => _$ScoreRecordRequestFromJson(json);
}


@lazySingleton
class SendScoreRecordUseCase implements UseCaseWithParams<ScoreRecordRequest, VoiceFeedbackEntity> {
  final ILessonRepository _repository;

  SendScoreRecordUseCase(this._repository);

  @override
  TaskEither<AppException, VoiceFeedbackEntity> call(ScoreRecordRequest params) {
    return _repository.sendScoreRecord(params);
  }
}
