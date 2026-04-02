part of '../../output_practice.dart';

@freezed
abstract class OutputPracticeConversationEntity with _$OutputPracticeConversationEntity {
  const factory OutputPracticeConversationEntity({
    @Default('') @JsonKey(name: '_id') String id,
    @Default('') String userId,
    @Default('') String sectionId,
    @Default('') String threadId,
    @Default(0) int lastSeq,
    @JsonKey(unknownEnumValue: OutputPracticeConversationStatus.unknown) @Default(OutputPracticeConversationStatus.unknown) OutputPracticeConversationStatus status,
    @Default(OutputPracticeAiReplyEntity()) OutputPracticeAiReplyEntity reply,
  }) = _OutputPracticeConversationEntity;

  factory OutputPracticeConversationEntity.fromJson(Map<String, dynamic> json) => _$OutputPracticeConversationEntityFromJson(json);
}

extension OutputPracticeConversationEntityX on OutputPracticeConversationEntity {
  bool get hasConversation => id.isNotEmpty;

  bool get isActive => status == OutputPracticeConversationStatus.active;

  bool get isSelectOptionPending => status == OutputPracticeConversationStatus.selectOptionPending;

  bool get isSummaryDecisionPending => status == OutputPracticeConversationStatus.summaryDecisionPending;

  bool get isConversationLimitInMonth => status == OutputPracticeConversationStatus.conversationLimitInMonth;

  bool get isFinished => status == OutputPracticeConversationStatus.finished;

  OutputPracticeConversationStatus effectiveStatus({required bool liveSummaryTurn}) {
    if (isFinished) return OutputPracticeConversationStatus.finished;
    if (isConversationLimitInMonth) {
      return OutputPracticeConversationStatus.conversationLimitInMonth;
    }
    if (liveSummaryTurn) return OutputPracticeConversationStatus.summaryDecisionPending;
    return status;
  }
}
