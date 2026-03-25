part of '../../output_practice.dart';

@freezed
abstract class OutputPracticeConversationModel with _$OutputPracticeConversationModel {
  const factory OutputPracticeConversationModel({
    @Default('') String id,
    @Default('') String userId,
    @Default('') String sectionId,
    @Default('') String threadId,
    @Default(0) int lastSeq,
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
        reply: reply.toEntity(),
      );
}

