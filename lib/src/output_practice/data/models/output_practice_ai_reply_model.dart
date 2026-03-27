part of '../../output_practice.dart';

@freezed
abstract class OutputPracticeAiReplyModel with _$OutputPracticeAiReplyModel {
  const factory OutputPracticeAiReplyModel({
    @Default('') String id,
    @JsonKey(unknownEnumValue: OutputPracticeMessageType.unknown) @Default(OutputPracticeMessageType.unknown) OutputPracticeMessageType type,
    @Default('') String content,
    @Default([]) List<OutputPracticeAiReplyOptionModel> options,
  }) = _OutputPracticeAiReplyModel;

  factory OutputPracticeAiReplyModel.fromJson(Map<String, dynamic> json) => _$OutputPracticeAiReplyModelFromJson(json);
}

extension OutputPracticeAiReplyModelExtension on OutputPracticeAiReplyModel {
  OutputPracticeAiReplyEntity toEntity() => OutputPracticeAiReplyEntity(
    id: id,
    type: type,
    content: content,
    options: options.map((o) => o.toEntity()).toList(),
  );
}

enum OutputPracticeMessageType {
  @JsonValue('message')
  message,
  @JsonValue('select_option')
  selectOption,
  @JsonValue('summary_decision')
  summaryDecision,
  @JsonValue('unknown')
  unknown,
}
