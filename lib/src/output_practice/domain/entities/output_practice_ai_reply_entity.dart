part of '../../output_practice.dart';

@freezed
abstract class OutputPracticeAiReplyEntity with _$OutputPracticeAiReplyEntity {
  const factory OutputPracticeAiReplyEntity({
    @Default('') String id,
    @JsonKey(unknownEnumValue: OutputPracticeMessageType.unknown) @Default(OutputPracticeMessageType.unknown) OutputPracticeMessageType type,
    @Default('') String content,
    @Default([]) List<OutputPracticeAiReplyOptionEntity> options,
  }) = _OutputPracticeAiReplyEntity;

  factory OutputPracticeAiReplyEntity.fromJson(Map<String, dynamic> json) => _$OutputPracticeAiReplyEntityFromJson(json);
}
