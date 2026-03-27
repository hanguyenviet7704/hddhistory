part of '../../output_practice.dart';

@freezed
abstract class OutputPracticeMessageEntity with _$OutputPracticeMessageEntity {
  const factory OutputPracticeMessageEntity({
    @Default('') String conversationId,
    @Default(0) int seq,
    @Default('') String content,
    @JsonKey(unknownEnumValue: OutputPracticeMessageType.unknown) @Default(OutputPracticeMessageType.unknown) OutputPracticeMessageType type,
    @Default(OutputPracticeMessageRole.user) OutputPracticeMessageRole role,
  }) = _OutputPracticeMessageEntity;

  factory OutputPracticeMessageEntity.fromJson(Map<String, dynamic> json) =>
      _$OutputPracticeMessageEntityFromJson(json);
}

extension OutputPracticeMessagesEntityExtension on List<OutputPracticeMessageEntity> {
  List<OutputPracticeMessageEntity> get userMessages => where((message) => message.role == OutputPracticeMessageRole.user).toList();
}