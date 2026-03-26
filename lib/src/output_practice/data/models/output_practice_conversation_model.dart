part of '../../output_practice.dart';

@freezed
abstract class OutputPracticeConversationModel with _$OutputPracticeConversationModel {
  const factory OutputPracticeConversationModel({
    @Default('') String id,
    @Default('') String userId,
    @Default('') String sectionId,
    @Default('') String threadId,
    @Default(0) int lastSeq,
    @Default(false) bool summaryDecisionPending,
    @Default(false) bool conversationEnded,
    @Default(OutputPracticeAiReplyModel()) OutputPracticeAiReplyModel reply,
  }) = _OutputPracticeConversationModel;

  factory OutputPracticeConversationModel.fromJson(Map<String, dynamic> json) =>
      _$OutputPracticeConversationModelFromJson(json);
}

extension OutputPracticeConversationModelExtension on OutputPracticeConversationModel {
  OutputPracticeConversationEntity toEntity() => OutputPracticeConversationEntity(
        id: id,
        userId: userId,
        sectionId: sectionId,
        threadId: threadId,
        lastSeq: lastSeq,
        summaryDecisionPending: summaryDecisionPending,
        conversationEnded: conversationEnded,
        reply: reply.toEntity(),
      );
}

