part of '../../output_practice.dart';

OutputPracticeActionChipVm? _matchActionChip(String input, List<OutputPracticeActionChipVm> chips) {
  final normalizedInput = _normalizeOutputPracticeInput(input);
  if (normalizedInput.isEmpty) return null;

  for (final chip in chips) {
    if (_normalizeOutputPracticeInput(chip.label) == normalizedInput) {
      return chip;
    }
  }
  return null;
}

String _normalizeOutputPracticeInput(String input) {
  return input.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}

List<OutputPracticeActionChipVm> _buildActionChips(
  OutputPracticeConversationEntity conversation, {
  required bool liveSummaryTurn,
}) {
  if (conversation.isFinished) return const [];
  if (conversation.isSummaryDecisionPending || liveSummaryTurn) {
    return [
      OutputPracticeActionChipVm.summary(OutputPracticeSummaryAction.continueDeeper),
      OutputPracticeActionChipVm.summary(OutputPracticeSummaryAction.newChallenge),
      OutputPracticeActionChipVm.summary(OutputPracticeSummaryAction.differentScenario),
      OutputPracticeActionChipVm.summary(OutputPracticeSummaryAction.endPractice),
    ];
  }
  return conversation.reply.options.map(OutputPracticeActionChipVm.option).toList();
}

List<OutputPracticeTimelineItem> _timelineFromMessages(List<OutputPracticeMessageEntity> messages) {
  return messages.sortedBySeqAsc.where((message) => message.role == OutputPracticeMessageRole.user || message.role == OutputPracticeMessageRole.assistant).map((message) {
    final id = _timelineIdForMessage(message);
    if (message.role == OutputPracticeMessageRole.assistant) {
      return OutputPracticeTimelineItem.assistant(id: id, content: message.content);
    }
    return OutputPracticeTimelineItem.user(id: id, content: message.content);
  }).toList();
}

List<OutputPracticeTimelineItem> _prependTimelineItems(
  List<OutputPracticeTimelineItem> current,
  List<OutputPracticeMessageEntity> olderMessages,
) {
  final olderItems = _timelineFromMessages(olderMessages);
  final existingIds = current.map((item) => item.id).toSet();
  final prependItems = olderItems.where((item) => !existingIds.contains(item.id)).toList();
  return [...prependItems, ...current];
}

List<OutputPracticeTimelineItem> _replacePendingTurnWithCanonical(
  OutputPracticeState state,
  List<OutputPracticeMessageEntity> canonicalMessages,
) {
  final canonicalItems = _timelineFromMessages(canonicalMessages);
  final hasCanonicalUser = canonicalMessages.any((message) => message.role == OutputPracticeMessageRole.user);
  final hasCanonicalAssistant = canonicalMessages.any((message) => message.role == OutputPracticeMessageRole.assistant);
  final timeline = state.timelineItems
      .where((item) {
        if (item.id == state.pendingMessageLocalId) return !hasCanonicalUser;
        if (item.id == state.pendingAssistantLocalId) return !hasCanonicalAssistant;
        return item.deliveryStatus == OutputPracticeDeliveryStatus.confirmed;
      })
      .map((item) {
        if (item.id == state.pendingMessageLocalId) {
          return item.copyWith(deliveryStatus: OutputPracticeDeliveryStatus.confirmed);
        }
        if (item.id == state.pendingAssistantLocalId) {
          return item.copyWith(isStreaming: false);
        }
        return item;
      })
      .toList();

  final existingIds = timeline.map((item) => item.id).toSet();
  for (final item in canonicalItems) {
    if (existingIds.add(item.id)) {
      timeline.add(item);
    }
  }
  return timeline;
}

OutputPracticeTimelineItem _appendOrUpdateAssistantDraft(
  List<OutputPracticeTimelineItem> timeline,
  String assistantDraftId,
  String chunk,
) {
  final index = timeline.indexWhere((item) => item.id == assistantDraftId);
  if (index == -1) {
    return OutputPracticeTimelineItem.assistant(
      id: assistantDraftId,
      content: chunk,
      isStreaming: true,
    );
  }

  return timeline[index].copyWith(
    content: '${timeline[index].content}$chunk',
    isStreaming: true,
  );
}

String _timelineIdForMessage(OutputPracticeMessageEntity message) {
  return 'message_${message.seq}_${message.role.name}';
}
