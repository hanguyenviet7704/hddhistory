part of '../../output_practice.dart';

@freezed
abstract class OutputPracticeAiStartResponseModel with _$OutputPracticeAiStartResponseModel {
  const factory OutputPracticeAiStartResponseModel({
    @Default('') String threadId,
    OutputPracticeAiReplyModel? reply,
  }) = _OutputPracticeAiStartResponseModel;

  factory OutputPracticeAiStartResponseModel.fromJson(Map<String, dynamic> json) =>
      _$OutputPracticeAiStartResponseModelFromJson(json);
}
