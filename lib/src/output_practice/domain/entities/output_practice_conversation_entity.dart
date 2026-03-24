part of '../../output_practice.dart';

@freezed
abstract class OutputPracticeConversationEntity with _$OutputPracticeConversationEntity {
  const factory OutputPracticeConversationEntity({
    @Default('') String userId,
    @Default('') String sectionId,
    @Default('') String threadId,
    @Default(0) int lastSeq,
    OutputPracticeAiReplyEntity? reply,
  }) = _OutputPracticeConversationEntity;

  factory OutputPracticeConversationEntity.fromJson(Map<String, dynamic> json) =>
      _$OutputPracticeConversationEntityFromJson(json);
}

