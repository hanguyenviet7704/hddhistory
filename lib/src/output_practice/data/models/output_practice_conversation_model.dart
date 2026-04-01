part of '../../output_practice.dart';

@freezed
abstract class OutputPracticeConversationModel with _$OutputPracticeConversationModel {
  const factory OutputPracticeConversationModel({
    @Default('') @JsonKey(name: '_id') String id,
    @Default('') String userId,
    @Default('') String sectionId,
    @Default('') String threadId,
    @Default(0) int lastSeq,
    @JsonKey(unknownEnumValue: OutputPracticeConversationStatus.unknown) @Default(OutputPracticeConversationStatus.unknown) OutputPracticeConversationStatus status,
    @Default(OutputPracticeAiReplyModel()) OutputPracticeAiReplyModel reply,
  }) = _OutputPracticeConversationModel;

  factory OutputPracticeConversationModel.fromJson(Map<String, dynamic> json) =>
      _$OutputPracticeConversationModelFromJson(json);
}

enum OutputPracticeConversationStatus {
  @JsonValue('active')
  active,
  @JsonValue('select_option_pending')
  selectOptionPending,
  @JsonValue('summary_decision_pending')
  summaryDecisionPending,
  @JsonValue('finished')
  finished,
  @JsonValue('conversation_limit_in_month')
  conversationLimitInMonth,
  @JsonValue('unknown')
  unknown,
}

extension OutputPracticeConversationModelExtension on OutputPracticeConversationModel {
  OutputPracticeConversationEntity toEntity() => OutputPracticeConversationEntity(
        id: id,
        userId: userId,
        sectionId: sectionId,
        threadId: threadId,
        lastSeq: lastSeq,
        status: status,
        reply: reply.toEntity(),
      );
}

