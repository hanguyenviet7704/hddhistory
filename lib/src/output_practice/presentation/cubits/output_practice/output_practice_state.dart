part of '../../../output_practice.dart';

enum OutputPracticeUiMode { initial, loading, ready, unavailable }

enum OutputPracticeHistoryStatus { initial, loading, success, failure }

enum OutputPracticeSendStatus { idle, waitingSocket, streaming }

enum OutputPracticeEntryState { unknown, existing, created }

@freezed
abstract class OutputPracticeState with _$OutputPracticeState {
  const factory OutputPracticeState({
    @Default(OutputPracticeUiMode.initial) OutputPracticeUiMode uiMode,
    @Default(OutputPracticeHistoryStatus.initial) OutputPracticeHistoryStatus historyStatus,
    @Default(OutputPracticeSendStatus.idle) OutputPracticeSendStatus sendStatus,
    @Default(OutputPracticeEntryState.unknown) OutputPracticeEntryState entryState,
    @Default(OutputPracticeConversationUsageEntity()) OutputPracticeConversationUsageEntity conversationUsage,
    @Default(LessonEntity()) LessonEntity currentLesson,
    @Default(LessonEntity()) LessonEntity detailedLesson,
    @Default(OutputPracticeConversationEntity()) OutputPracticeConversationEntity conversation,
    @Default([]) List<OutputPracticeTimelineItem> timelineItems,
    @Default([]) List<OutputPracticeActionChipVm> activeActionChips,
    @Default([]) List<OutputPracticeActionChipVm> hiddenActionChips,
    @Default('') String currentSectionId,
    @Default('') String currentConversationId,
    @Default('') String joinedRoomId,
    @Default('') String inputText,
    String? historyErrorMessage,
    String? unavailableMessage,
    String? roomErrorMessage,
    String? pendingMessageText,
    @Default(false) bool pendingWasFreeText,
    @Default(false) bool awaitingActionTurnCompletion,
    @Default('') String pendingMessageLocalId,
    @Default('') String pendingAssistantLocalId,
    @Default(false) bool liveSummaryTurn,
    @Default(false) bool screenViewTracked,
    @Default(1) int currentHistoryPage,
    @Default(1) int totalHistoryPages,
    @Default(true) bool isNearBottom,
    @Default(false) bool showJumpToLatest,
  }) = _OutputPracticeState;

  factory OutputPracticeState.initial() => const OutputPracticeState();
}

extension OutputPracticeStateX on OutputPracticeState {
  LessonEntity get displayLesson => detailedLesson.id.isNotEmpty ? detailedLesson : currentLesson;

  OutputPracticeConversationStatus get effectiveConversationStatus => conversation.effectiveStatus(liveSummaryTurn: liveSummaryTurn);

  String get assistantNameOrFallback => displayLesson.animation.name;

  String get assistantAvatarUrl => displayLesson.animation.url;

  bool get hasHistoryError => historyStatus == OutputPracticeHistoryStatus.failure;

  bool get isInitialized => currentSectionId.isNotEmpty && uiMode != OutputPracticeUiMode.initial;

  bool get isLoading => uiMode == OutputPracticeUiMode.loading;

  bool get isFinished => conversation.isFinished;

  bool get isSummaryMode => effectiveConversationStatus == OutputPracticeConversationStatus.summaryDecisionPending;

  bool get isWaitingForSocket => sendStatus == OutputPracticeSendStatus.waitingSocket;

  bool get isStreaming => sendStatus == OutputPracticeSendStatus.streaming;

  bool get isInputEnabled {
    final historyReady = historyStatus == OutputPracticeHistoryStatus.success;
    final roomReady = joinedRoomId.isNotEmpty;
    return uiMode == OutputPracticeUiMode.ready &&
        historyReady &&
        roomReady &&
        sendStatus == OutputPracticeSendStatus.idle &&
        effectiveConversationStatus == OutputPracticeConversationStatus.active;
  }

  bool get canSubmitActionChip {
    final historyReady = historyStatus == OutputPracticeHistoryStatus.success;
    final roomReady = joinedRoomId.isNotEmpty;
    if (uiMode != OutputPracticeUiMode.ready || !historyReady || !roomReady) {
      return false;
    }
    if (sendStatus != OutputPracticeSendStatus.idle || activeActionChips.isEmpty) {
      return false;
    }

    return switch (effectiveConversationStatus) {
      OutputPracticeConversationStatus.selectOptionPending ||
      OutputPracticeConversationStatus.summaryDecisionPending ||
      OutputPracticeConversationStatus.finished ||
      OutputPracticeConversationStatus.conversationLimitInMonth => true,
      _ => false,
    };
  }

  bool get canRetryHistory => currentConversationId.isNotEmpty;

  bool get canLoadMoreHistory => historyStatus == OutputPracticeHistoryStatus.success && currentHistoryPage < totalHistoryPages && currentConversationId.isNotEmpty;
}
