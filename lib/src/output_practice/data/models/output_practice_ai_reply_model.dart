part of '../../output_practice.dart';

@freezed
abstract class OutputPracticeAiReplyModel with _$OutputPracticeAiReplyModel {
  const factory OutputPracticeAiReplyModel({
    String? type,
    String? content,
    @Default([]) List<OutputPracticeAiReplyOptionModel> options,
  }) = _OutputPracticeAiReplyModel;

  factory OutputPracticeAiReplyModel.fromJson(Map<String, dynamic> json) =>
      _$OutputPracticeAiReplyModelFromJson(json);
}

extension OutputPracticeAiReplyModelExtension on OutputPracticeAiReplyModel {
  OutputPracticeAiReplyEntity toEntity() => OutputPracticeAiReplyEntity(
        type: type,
        content: content,
        options: options.map((o) => o.toEntity()).toList(),
      );
}
