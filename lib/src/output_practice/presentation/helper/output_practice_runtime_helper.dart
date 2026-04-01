part of '../../output_practice.dart';

// Behavioral conflicts in the raw docs are resolved in favor of flow.md.
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
  final status = conversation.effectiveStatus(liveSummaryTurn: liveSummaryTurn);
  return switch (status) {
    OutputPracticeConversationStatus.summaryDecisionPending => [
      OutputPracticeActionChipVm.summary(OutputPracticeSummaryAction.endPractice),
      OutputPracticeActionChipVm.summary(OutputPracticeSummaryAction.startANewConversation),
    ],
    OutputPracticeConversationStatus.finished || OutputPracticeConversationStatus.conversationLimitInMonth => [
      OutputPracticeActionChipVm.summary(OutputPracticeSummaryAction.startANewConversation),
    ],
    OutputPracticeConversationStatus.selectOptionPending => conversation.reply.options.map(OutputPracticeActionChipVm.option).toList(),
    _ => const [],
  };
}

List<OutputPracticeActionChipVm> _buildVisibleActionChips(
  OutputPracticeConversationEntity conversation, {
  required bool liveSummaryTurn,
  required List<OutputPracticeTimelineItem> timelineItems,
}) {
  final chips = _buildActionChips(conversation, liveSummaryTurn: liveSummaryTurn);
  if (chips.isEmpty) return chips;
  final status = conversation.effectiveStatus(liveSummaryTurn: liveSummaryTurn);
  if (status == OutputPracticeConversationStatus.finished || status == OutputPracticeConversationStatus.conversationLimitInMonth) {
    return chips;
  }
  if (_hasConsumedCurrentTurnAction(timelineItems, chips)) {
    return const [];
  }
  return chips;
}

bool _hasConsumedCurrentTurnAction(
  List<OutputPracticeTimelineItem> timelineItems,
  List<OutputPracticeActionChipVm> chips,
) {
  for (var index = timelineItems.length - 1; index >= 0; index--) {
    final item = timelineItems[index];
    if (item.deliveryStatus == OutputPracticeDeliveryStatus.failed) continue;
    if (!item.isUser) return false;

    if (item.messageType == OutputPracticeMessageType.selectOption) {
      return chips.any((chip) => chip.kind == OutputPracticeActionKind.option);
    }
    if (item.messageType == OutputPracticeMessageType.summaryDecision) {
      return chips.any((chip) => chip.kind == OutputPracticeActionKind.summaryDecision);
    }
    if (item.messageType == OutputPracticeMessageType.unknown) {
      return _matchActionChip(item.content, chips) != null;
    }
    return false;
  }
  return false;
}

bool _hasConversationActionStateAdvanced(
  OutputPracticeConversationEntity previous,
  OutputPracticeConversationEntity next,
) {
  if (previous.id != next.id) return true;
  if (previous.status != next.status) return true;
  if (previous.lastSeq != next.lastSeq) return true;

  final previousOptions = previous.reply.options;
  final nextOptions = next.reply.options;
  if (previousOptions.length != nextOptions.length) return true;

  for (var index = 0; index < previousOptions.length; index++) {
    final previousOption = previousOptions[index];
    final nextOption = nextOptions[index];
    if (previousOption.value != nextOption.value) return true;
    if (previousOption.label != nextOption.label) return true;
    if (previousOption.description != nextOption.description) return true;
  }

  return false;
}

List<OutputPracticeTimelineItem> _timelineFromMessages(List<OutputPracticeMessageEntity> messages) {
  return messages.sortedBySeqAsc.where((message) => message.role == OutputPracticeMessageRole.user || message.role == OutputPracticeMessageRole.assistant).map((message) {
    final id = _timelineIdForMessage(message);
    if (message.role == OutputPracticeMessageRole.assistant) {
      return OutputPracticeTimelineItem.assistant(
        id: id,
        content: message.content,
        messageType: message.type,
        serverSeq: message.seq,
      );
    }
    return OutputPracticeTimelineItem.user(
      id: id,
      content: message.content,
      messageType: message.type,
      serverSeq: message.seq,
    );
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
