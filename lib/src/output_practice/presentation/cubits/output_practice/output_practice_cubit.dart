part of '../../../output_practice.dart';

@lazySingleton
class OutputPracticeCubit extends Cubit<OutputPracticeState> {
  OutputPracticeCubit(
    this._getConversationUseCase,
    this._getConversationUsageUseCase,
    this._getAllMessagesUseCase,
    this._createConversationUseCase,
    this._sendMessageUseCase,
    this._getCourseLessonUseCase,
  ) : super(OutputPracticeState.initial());

  final GetOutputPracticeConversationUseCase _getConversationUseCase;
  final GetOutputPracticeConversationUsageUseCase _getConversationUsageUseCase;
  final GetAllOutputPracticeMessagesUseCase _getAllMessagesUseCase;
  final CreateOutputPracticeConversationUseCase _createConversationUseCase;
  final SendOutputPracticeMessageUseCase _sendMessageUseCase;
  final GetCourseLessonUseCase _getCourseLessonUseCase;
  int _sessionToken = 0;

  void reset() {
    _sessionToken += 1;
    emit(OutputPracticeState.initial());
  }

  void preloadEntry({
    required LessonEntity lesson,
    required String sectionId,
  }) {
    _sessionToken += 1;
    emit(
      OutputPracticeState.initial().copyWith(
        currentLesson: lesson,
        currentSectionId: sectionId,
      ),
    );
  }

  void updateInputText(String value) => emit(state.copyWith(inputText: value));

  void updateScrollState({required bool isNearBottom}) {
    emit(
      state.copyWith(
        isNearBottom: isNearBottom,
        showJumpToLatest: !isNearBottom && state.showJumpToLatest,
      ),
    );
  }

  void markScreenViewTracked() {
    if (state.screenViewTracked) return;
    emit(state.copyWith(screenViewTracked: true));
  }

  OutputPracticeActionChipVm? matchTextToAction(String text) {
    return _matchActionChip(text, state.activeActionChips);
  }

  Future<void> initialize(String sectionId) async {
    final sessionToken = ++_sessionToken;
    if (sectionId.isEmpty) {
      emit(
        state.copyWith(
          uiMode: OutputPracticeUiMode.unavailable,
        ),
      );
      return;
    }

    final preloadedLesson = state.currentSectionId == sectionId ? state.currentLesson : const LessonEntity();
    emit(
      OutputPracticeState.initial().copyWith(
        uiMode: OutputPracticeUiMode.loading,
        currentSectionId: sectionId,
        currentLesson: preloadedLesson,
      ),
    );

    if (preloadedLesson.id.isNotEmpty) {
      final lessonResult = await _getCourseLessonUseCase(preloadedLesson.id).run();
      if (!_isSessionActive(sessionToken, sectionId: sectionId)) return;
      lessonResult.fold((_) {}, (lesson) => emit(state.copyWith(detailedLesson: lesson)));
    }

    var createdConversation = false;
    final conversationResult = await _getConversationUseCase(sectionId).run();
    if (!_isSessionActive(sessionToken, sectionId: sectionId)) return;
    final resolvedConversation = await conversationResult.fold(
      (exception) async {
        if (!_isSessionActive(sessionToken, sectionId: sectionId)) return null;
        if (exception is! NotFoundException) {
          emit(
            state.copyWith(
              uiMode: OutputPracticeUiMode.unavailable,
              unavailableMessage: exception.displayMessage,
            ),
          );
          return null;
        }

        createdConversation = true;
        return _createConversation(sectionId, sessionToken: sessionToken);
      },
      (conversation) async {
        if (conversation.hasConversation) return conversation;
        createdConversation = true;
        return _createConversation(sectionId, sessionToken: sessionToken);
      },
    );

    if (!_isSessionActive(sessionToken, sectionId: sectionId)) return;
    if (resolvedConversation == null || !resolvedConversation.hasConversation) return;

    emit(
      state.copyWith(
        uiMode: OutputPracticeUiMode.loading,
        entryState: createdConversation ? OutputPracticeEntryState.created : OutputPracticeEntryState.existing,
        conversation: resolvedConversation,
        currentConversationId: resolvedConversation.id,
        activeActionChips: _resolveActionChips(
          resolvedConversation,
          liveSummaryTurn: false,
          timelineItems: state.timelineItems,
        ),
      ),
    );

    await _loadHistory(forcePage: 1, sessionToken: sessionToken);
  }

  Future<void> retryHistory() => _loadHistory(forcePage: 1);

  Future<void> loadOlderHistory() {
    if (!state.canLoadMoreHistory) return Future.value();
    return _loadHistory(forcePage: state.currentHistoryPage + 1);
  }

  void markRoomJoined(String roomId) {
    if (roomId.isEmpty || roomId != state.currentConversationId) return;
    emit(
      state.copyWith(
        joinedRoomId: roomId,
        roomErrorMessage: null,
        activeActionChips: _resolveActionChips(
          state.conversation,
          liveSummaryTurn: state.liveSummaryTurn,
          timelineItems: state.timelineItems,
          hasJoinedRoom: true,
        ),
      ),
    );
  }

  void markRoomJoinFailed(String roomId, String? message) {
    if (roomId.isEmpty || roomId != state.currentConversationId) return;
    emit(
      state.copyWith(
        joinedRoomId: '',
        roomErrorMessage: message,
        activeActionChips: const [],
      ),
    );
  }

  Future<void> handleSocketEvent(OutputPracticeAiStreamEvent event) async {
    final eventConversationId = event.conversationId ?? '';
    if (eventConversationId.isNotEmpty && eventConversationId != state.currentConversationId) return;
    switch (event) {
      case _OutputPracticeAiStreamEventStream(:final content):
        final draftId = state.pendingAssistantLocalId.isNotEmpty ? state.pendingAssistantLocalId : 'assistant_draft';
        final timeline = [...state.timelineItems];
        final draft = _appendOrUpdateAssistantDraft(timeline, draftId, content);
        final index = timeline.indexWhere((item) => item.id == draftId);
        if (index == -1) {
          timeline.add(draft);
        } else {
          timeline[index] = draft;
        }
        emit(
          state.copyWith(
            sendStatus: OutputPracticeSendStatus.streaming,
            pendingAssistantLocalId: draftId,
            timelineItems: timeline,
            showJumpToLatest: !state.isNearBottom,
          ),
        );
      case _OutputPracticeAiStreamEventMetadataUpdate(:final isSummaryTurn):
        final liveSummaryTurn = isSummaryTurn ?? false;
        emit(
          state.copyWith(
            liveSummaryTurn: liveSummaryTurn,
            activeActionChips: _resolveActionChips(
              state.conversation,
              liveSummaryTurn: liveSummaryTurn,
              timelineItems: state.timelineItems,
            ),
          ),
        );
      case _OutputPracticeAiStreamEventEnd():
        if (state.pendingAssistantLocalId.isNotEmpty) {
          final timeline = state.timelineItems.map((item) {
            if (item.id != state.pendingAssistantLocalId) return item;
            return item.copyWith(isStreaming: false);
          }).toList();
          emit(state.copyWith(timelineItems: timeline));
        }
        await _refreshConversationAfterSocketTurn(conversationId: eventConversationId);
      case _OutputPracticeAiStreamEventError():
        _handleSendFailure('The practice response was interrupted.');
      case _OutputPracticeAiStreamEventUnknown():
        return;
    }
  }

  Future<void> sendCurrentInput() async {
    if (!state.isInputEnabled) return;

    final text = state.inputText.trim();
    if (text.isEmpty) return;
    final matchedChip = matchTextToAction(text);
    if (matchedChip != null) {
      await sendActionChip(matchedChip, committedText: matchedChip.label);
      return;
    }

    await _sendAction(
      committedText: text,
      body: {
        'conversationId': state.currentConversationId,
        'type': 'message',
        'message': text,
      },
      isFreeText: true,
      awaitingActionTurnCompletion: false,
      pendingMessageType: OutputPracticeMessageType.message,
    );
  }

  Future<void> sendActionChip(OutputPracticeActionChipVm chip, {String? committedText}) {
    if (!state.canSubmitActionChip) return Future.value();
    if (chip.summaryAction == OutputPracticeSummaryAction.startANewConversation) {
      return startNewConversation();
    }
    final isSelectOption = chip.kind == OutputPracticeActionKind.option;
    final type = isSelectOption ? 'select_option' : 'summary_decision';
    return _sendAction(
      committedText: committedText ?? chip.label,
      body: {
        'conversationId': state.currentConversationId,
        'type': type,
        'value': chip.value,
      },
      isFreeText: false,
      awaitingActionTurnCompletion: true,
      pendingMessageType: isSelectOption ? OutputPracticeMessageType.selectOption : OutputPracticeMessageType.summaryDecision,
    );
  }

  Future<void> startNewConversation() async {
    if (!state.canSubmitActionChip) return;

    final previousState = state;
    final sessionToken = _sessionToken;
    final activeSectionId = state.currentSectionId;
    if (activeSectionId.isEmpty) return;

    emit(
      state.copyWith(
        uiMode: OutputPracticeUiMode.loading,
        historyStatus: OutputPracticeHistoryStatus.loading,
        timelineItems: const [],
        activeActionChips: const [],
        hiddenActionChips: const [],
        historyErrorMessage: null,
        roomErrorMessage: null,
        liveSummaryTurn: false,
        pendingMessageText: null,
        pendingWasFreeText: false,
        awaitingActionTurnCompletion: false,
        pendingMessageLocalId: '',
        pendingAssistantLocalId: '',
        sendStatus: OutputPracticeSendStatus.idle,
        currentHistoryPage: 1,
        totalHistoryPages: 1,
        showJumpToLatest: false,
      ),
    );

    final createResult = await _createConversationUseCase({
      'sectionId': activeSectionId,
      'language': AppDI.injector.get<LocaleCubit>().state.languageAISupport,
    }).run();
    if (!_isSessionActive(sessionToken, sectionId: activeSectionId)) return;

    final createdConversation = createResult.fold(
      (exception) {
        emit(previousState.copyWith(roomErrorMessage: exception.displayMessage));
        return null;
      },
      (conversation) => conversation,
    );
    if (createdConversation == null || !_isSessionActive(sessionToken, sectionId: activeSectionId)) {
      return;
    }

    final refreshedConversation = (await _getConversationUseCase(activeSectionId).run()).getOrElse((_) => createdConversation);
    if (!_isSessionActive(sessionToken, sectionId: activeSectionId)) return;

    final nextConversationId = refreshedConversation.id;
    emit(
      state.copyWith(
        entryState: OutputPracticeEntryState.created,
        conversation: refreshedConversation,
        currentConversationId: nextConversationId,
        joinedRoomId: nextConversationId == previousState.currentConversationId ? previousState.joinedRoomId : '',
        activeActionChips: const [],
      ),
    );

    await _refreshUsage(sectionId: activeSectionId, sessionToken: sessionToken);
    await _loadHistory(forcePage: 1, sessionToken: sessionToken);
  }

  Future<void> retryFailedMessage() async {
    final text = state.pendingMessageText;
    if (text == null || text.isEmpty) return;
    updateInputText(text);
    await sendCurrentInput();
  }

  Future<OutputPracticeConversationEntity?> _createConversation(
    String sectionId, {
    required int sessionToken,
  }) async {
    final result = await _createConversationUseCase({
      'sectionId': sectionId,
      'language': AppDI.injector.get<LocaleCubit>().state.languageAISupport,
    }).run();
    if (!_isSessionActive(sessionToken, sectionId: sectionId)) return null;

    return result.fold((exception) {
      emit(
        state.copyWith(
          uiMode: OutputPracticeUiMode.unavailable,
          unavailableMessage: exception.displayMessage,
        ),
      );
      return null;
    }, (conversation) => conversation);
  }

  Future<void> _loadHistory({int? forcePage, int? sessionToken}) async {
    final activeConversationId = state.currentConversationId;
    final activeSectionId = state.currentSectionId;
    final currentSessionToken = sessionToken ?? _sessionToken;
    if (activeConversationId.isEmpty) return;
    emit(state.copyWith(historyStatus: OutputPracticeHistoryStatus.loading, historyErrorMessage: null));

    final result = await _getAllMessagesUseCase(
      OutputPracticeMessagesRequestEntity(
        conversationId: activeConversationId,
        page: forcePage ?? 1,
      ),
    ).run();
    if (!_isSessionActive(
      currentSessionToken,
      sectionId: activeSectionId,
      conversationId: activeConversationId,
    )) {
      return;
    }

    result.fold(
      (exception) {
        emit(
          state.copyWith(
            uiMode: OutputPracticeUiMode.ready,
            historyStatus: OutputPracticeHistoryStatus.failure,
            historyErrorMessage: exception.displayMessage,
          ),
        );
      },
      (pageData) {
        final timelineItems = forcePage != null && forcePage > 1 ? _prependTimelineItems(state.timelineItems, pageData.items) : _timelineFromMessages(pageData.items);
        emit(
          state.copyWith(
            uiMode: OutputPracticeUiMode.ready,
            historyStatus: OutputPracticeHistoryStatus.success,
            timelineItems: timelineItems,
            currentHistoryPage: pageData.currentPage,
            totalHistoryPages: pageData.totalPages,
            activeActionChips: _resolveActionChips(
              state.conversation,
              liveSummaryTurn: state.liveSummaryTurn,
              timelineItems: timelineItems,
              historyStatus: OutputPracticeHistoryStatus.success,
            ),
            showJumpToLatest: false,
          ),
        );
      },
    );
  }

  Future<void> _sendAction({
    required String committedText,
    required Map<String, dynamic> body,
    required bool isFreeText,
    required bool awaitingActionTurnCompletion,
    required OutputPracticeMessageType pendingMessageType,
  }) async {
    final sessionToken = _sessionToken;
    final activeConversationId = state.currentConversationId;
    final activeSectionId = state.currentSectionId;
    final pendingMessageLocalId = 'pending_${DateTime.now().microsecondsSinceEpoch}';
    emit(
      state.copyWith(
        timelineItems: [
          ...state.timelineItems,
          OutputPracticeTimelineItem.user(
            id: pendingMessageLocalId,
            content: committedText,
            deliveryStatus: OutputPracticeDeliveryStatus.sending,
            messageType: pendingMessageType,
          ),
        ],
        hiddenActionChips: [...state.activeActionChips],
        activeActionChips: const [],
        inputText: '',
        pendingWasFreeText: isFreeText,
        pendingMessageText: committedText,
        awaitingActionTurnCompletion: awaitingActionTurnCompletion,
        pendingMessageLocalId: pendingMessageLocalId,
        pendingAssistantLocalId: 'assistant_$pendingMessageLocalId',
        sendStatus: OutputPracticeSendStatus.waitingSocket,
        showJumpToLatest: !state.isNearBottom,
      ),
    );

    final result = await _sendMessageUseCase(body).run();
    if (!_isSessionActive(
      sessionToken,
      sectionId: activeSectionId,
      conversationId: activeConversationId,
    )) {
      return;
    }
    await result.match(
      (exception) async => _handleSendFailure(exception.displayMessage),
      (canonicalMessages) async {
        final previousConversation = state.conversation;
        final refreshedConversation = (await _getConversationUseCase(state.currentSectionId).run()).getOrElse((_) => state.conversation);
        final refreshedUsage = isFreeText
            ? state.conversationUsage
            : await _refreshUsage(
                sectionId: activeSectionId,
                sessionToken: sessionToken,
                shouldEmit: false,
              );
        if (!_isSessionActive(
          sessionToken,
          sectionId: activeSectionId,
          conversationId: activeConversationId,
        )) {
          return;
        }
        final hasConversationAdvanced = _hasConversationActionStateAdvanced(previousConversation, refreshedConversation);
        final timelineItems = _replacePendingTurnWithCanonical(state, canonicalMessages);
        emit(
          state.copyWith(
            conversation: refreshedConversation,
            conversationUsage: refreshedUsage,
            liveSummaryTurn: false,
            timelineItems: timelineItems,
            activeActionChips: awaitingActionTurnCompletion
                ? const []
                : hasConversationAdvanced
                ? _resolveActionChips(
                    refreshedConversation,
                    liveSummaryTurn: false,
                    timelineItems: timelineItems,
                  )
                : const [],
            hiddenActionChips: awaitingActionTurnCompletion || hasConversationAdvanced ? const [] : [...state.hiddenActionChips],
            pendingMessageText: null,
            pendingWasFreeText: false,
            awaitingActionTurnCompletion: awaitingActionTurnCompletion,
            pendingMessageLocalId: '',
            pendingAssistantLocalId: '',
            sendStatus: OutputPracticeSendStatus.idle,
          ),
        );
      },
    );
  }

  bool _isSessionActive(
    int sessionToken, {
    String? sectionId,
    String? conversationId,
  }) {
    if (sessionToken != _sessionToken) return false;
    if (sectionId != null && sectionId.isNotEmpty && state.currentSectionId != sectionId) return false;
    if (conversationId != null && conversationId.isNotEmpty && state.currentConversationId != conversationId) return false;
    return true;
  }

  List<OutputPracticeActionChipVm> _resolveActionChips(
    OutputPracticeConversationEntity conversation, {
    required bool liveSummaryTurn,
    required List<OutputPracticeTimelineItem> timelineItems,
    OutputPracticeHistoryStatus? historyStatus,
    bool? awaitingActionTurnCompletion,
    bool? hasJoinedRoom,
  }) {
    if ((historyStatus ?? state.historyStatus) != OutputPracticeHistoryStatus.success) {
      return const [];
    }
    if (!(hasJoinedRoom ?? state.joinedRoomId.isNotEmpty)) {
      return const [];
    }
    if ((awaitingActionTurnCompletion ?? state.awaitingActionTurnCompletion) && !liveSummaryTurn) {
      return const [];
    }
    return _buildVisibleActionChips(
      conversation,
      liveSummaryTurn: liveSummaryTurn,
      timelineItems: timelineItems,
    );
  }

  Future<void> _refreshConversationAfterSocketTurn({
    required String conversationId,
  }) async {
    final sessionToken = _sessionToken;
    final activeSectionId = state.currentSectionId;
    final activeConversationId = conversationId.isNotEmpty ? conversationId : state.currentConversationId;
    if (activeSectionId.isEmpty || activeConversationId.isEmpty) return;

    final result = await _getConversationUseCase(activeSectionId).run();
    if (!_isSessionActive(
      sessionToken,
      sectionId: activeSectionId,
      conversationId: activeConversationId,
    )) {
      return;
    }

    final previousConversation = state.conversation;
    result.fold(
      (_) {},
      (refreshedConversation) {
        if (!_hasConversationActionStateAdvanced(previousConversation, refreshedConversation)) {
          if (state.awaitingActionTurnCompletion) {
            emit(
              state.copyWith(
                awaitingActionTurnCompletion: false,
                hiddenActionChips: const [],
              ),
            );
          }
          return;
        }
        emit(
          state.copyWith(
            conversation: refreshedConversation,
            liveSummaryTurn: false,
            activeActionChips: _resolveActionChips(
              refreshedConversation,
              liveSummaryTurn: false,
              timelineItems: state.timelineItems,
              awaitingActionTurnCompletion: false,
            ),
            hiddenActionChips: const [],
            awaitingActionTurnCompletion: false,
          ),
        );
      },
    );
  }

  Future<OutputPracticeConversationUsageEntity> _refreshUsage({
    required String sectionId,
    required int sessionToken,
    bool shouldEmit = true,
  }) async {
    final result = await _getConversationUsageUseCase(sectionId).run();
    if (!_isSessionActive(sessionToken, sectionId: sectionId)) {
      return state.conversationUsage;
    }

    return result.fold(
      (_) => state.conversationUsage,
      (usage) {
        if (shouldEmit) {
          emit(state.copyWith(conversationUsage: usage));
        }
        return usage;
      },
    );
  }

  void _handleSendFailure(String message) {
    emit(
      state.copyWith(
        timelineItems: state.pendingWasFreeText
            ? state.timelineItems
                  .map((item) => item.id == state.pendingMessageLocalId ? item.copyWith(deliveryStatus: OutputPracticeDeliveryStatus.failed) : item)
                  .where((item) => item.id != state.pendingAssistantLocalId)
                  .toList()
            : state.timelineItems.where((item) => item.id != state.pendingMessageLocalId && item.id != state.pendingAssistantLocalId).toList(),
        sendStatus: OutputPracticeSendStatus.idle,
        activeActionChips: [...state.hiddenActionChips],
        hiddenActionChips: const [],
        roomErrorMessage: message,
        awaitingActionTurnCompletion: false,
        pendingMessageLocalId: '',
        pendingAssistantLocalId: '',
        pendingMessageText: state.pendingWasFreeText ? state.pendingMessageText : null,
        pendingWasFreeText: false,
      ),
    );
  }
}
