part of '../../output_practice.dart';

@freezed
abstract class OutputPracticeAiReplyOptionModel with _$OutputPracticeAiReplyOptionModel {
  const factory OutputPracticeAiReplyOptionModel({
    @Default(0) int value,
    @Default('') String label,
    @Default('') String description,
  }) = _OutputPracticeAiReplyOptionModel;

  factory OutputPracticeAiReplyOptionModel.fromJson(Map<String, dynamic> json) => _$OutputPracticeAiReplyOptionModelFromJson(json);
}

extension OutputPracticeAiReplyOptionModelExtension on OutputPracticeAiReplyOptionModel {
  OutputPracticeAiReplyOptionEntity toEntity() => OutputPracticeAiReplyOptionEntity(
    value: value,
    label: label,
    description: description,
  );
}
