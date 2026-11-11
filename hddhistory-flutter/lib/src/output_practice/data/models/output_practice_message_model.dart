part of '../../output_practice.dart';

@freezed
abstract class OutputPracticeMessageModel with _$OutputPracticeMessageModel {
  const factory OutputPracticeMessageModel({
    @Default('') String conversationId,
    @Default(0) int seq,
    @Default('') String content,
    @JsonKey(unknownEnumValue: OutputPracticeMessageType.unknown) @Default(OutputPracticeMessageType.unknown) OutputPracticeMessageType type,
    @Default(OutputPracticeMessageRole.user) OutputPracticeMessageRole role,
  }) = _OutputPracticeMessageModel;

  factory OutputPracticeMessageModel.fromJson(Map<String, dynamic> json) => _$OutputPracticeMessageModelFromJson(json);
}

enum OutputPracticeMessageRole {
  @JsonValue('user')
  user,
  @JsonValue('assistant')
  assistant,
  @JsonValue('system')
  system,
}

extension OutputPracticeMessageModelExtension on OutputPracticeMessageModel {
  OutputPracticeMessageEntity toEntity() => OutputPracticeMessageEntity(
    conversationId: conversationId,
    seq: seq,
    content: content,
    type: type,
    role: role,
  );
}
