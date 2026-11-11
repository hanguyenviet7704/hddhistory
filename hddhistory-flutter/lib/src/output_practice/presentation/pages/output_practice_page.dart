part of '../../output_practice.dart';

class OutputPracticePage extends StatefulWidget {
  const OutputPracticePage({
    super.key,
    required this.sectionId,
  });

  final String sectionId;

  @override
  State<OutputPracticePage> createState() => _OutputPracticePageState();
}

class _OutputPracticePageState extends State<OutputPracticePage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final OutputPracticeCubit _outputPracticeCubit;
  late final OutputPracticeSocketCubit _outputPracticeSocketCubit;

  @override
  void initState() {
    super.initState();
    _outputPracticeCubit = context.read<OutputPracticeCubit>();
    _outputPracticeSocketCubit = context.read<OutputPracticeSocketCubit>();
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _outputPracticeCubit.initialize(widget.sectionId);
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    _controller.dispose();
    _outputPracticeSocketCubit.disconnect();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final cubit = context.read<OutputPracticeCubit>();
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentOffset = _scrollController.offset;
    cubit.updateScrollState(isNearBottom: maxScroll - currentOffset < 100);
    if (currentOffset < 240 && cubit.state.canLoadMoreHistory) {
      cubit.loadOlderHistory();
    }
  }

  CourseLessonTrackingData? _trackingData(OutputPracticeState state) {
    final lesson = state.displayLesson.id.isNotEmpty ? state.displayLesson : state.currentLesson;
    return CourseLessonTrackingData.fromLesson(context, lesson);
  }

  void _handleClose(OutputPracticeState state) {
    final trackingData = _trackingData(state);
    if (trackingData != null && state.currentConversationId.isNotEmpty && state.currentSectionId.isNotEmpty) {
      AppService.instance.appTrackingService.trackOutputPracticeExitClick(
        trackingData,
        sectionId: state.currentSectionId,
        conversationId: state.currentConversationId,
      );
    }
    context.read<OutputPracticeSocketCubit>().disconnect();
    CourseRoadmapRoute().go(context);
  }

  void _handleSend(OutputPracticeState state) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final trackingData = _trackingData(state);
    final cubit = context.read<OutputPracticeCubit>();
    final matchedChip = _matchResolvedChip(state, text);
    final matchedChipLabel = matchedChip == null ? null : _resolveChipLabel(matchedChip);

    if (trackingData != null && state.currentConversationId.isNotEmpty) {
      if (matchedChip != null) {
        AppService.instance.appTrackingService.trackOutputPracticeOptionClick(
          trackingData,
          sectionId: state.currentSectionId,
          conversationId: state.currentConversationId,
          optionLabel: matchedChipLabel!,
          optionValue: matchedChip.value,
          inputSource: 'typed_match',
        );
      } else {
        AppService.instance.appTrackingService.trackOutputPracticeSendClick(
          trackingData,
          sectionId: state.currentSectionId,
          conversationId: state.currentConversationId,
          messageLength: text.length,
        );
      }
    }

    if (matchedChip != null) {
      cubit.sendActionChip(matchedChip, committedText: matchedChipLabel);
      return;
    }

    cubit.sendCurrentInput();
  }

  String _resolveHeaderEyebrow(
    OutputPracticeState state,
    dynamic copy,
  ) {
    final usage = state.conversationUsage;
    if (usage.monthlyLimit > 0) {
      return copy.headerUsageRemaining(
        remaining: usage.remainingInThisMonth,
        monthlyLimit: usage.monthlyLimit,
      );
    }
    return copy.practiceLabel;
  }

  String _resolveChipLabel(OutputPracticeActionChipVm chip) {
    final copy = context.l10n.outputPractice;
    return switch (chip.summaryAction) {
      OutputPracticeSummaryAction.endPractice => copy.summaryEndPractice,
      OutputPracticeSummaryAction.startANewConversation => copy.summaryStartANewConversation,
      null => chip.label,
    };
  }

  OutputPracticeActionChipVm? _matchResolvedChip(
    OutputPracticeState state,
    String text,
  ) {
    final normalizedText = _normalizeOutputPracticeInput(text);
    for (final chip in state.activeActionChips) {
      if (_normalizeOutputPracticeInput(_resolveChipLabel(chip)) == normalizedText) {
        return chip;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        return;
      },
      child: MultiBlocListener(
        listeners: [
          BlocListener<OutputPracticeCubit, OutputPracticeState>(
            listenWhen: (previous, current) => previous.currentConversationId != current.currentConversationId && current.currentConversationId.isNotEmpty,
            listener: (context, state) => context.read<OutputPracticeSocketCubit>().connectAndJoin(state.currentConversationId),
          ),
          BlocListener<OutputPracticeSocketCubit, OutputPracticeSocketState>(
            listener: (context, socketState) {
              final cubit = context.read<OutputPracticeCubit>();
              if (socketState.isJoined) {
                cubit.markRoomJoined(socketState.activeRoomId);
              } else if (socketState.status == OutputPracticeSocketStatus.joinFailure) {
                cubit.markRoomJoinFailed(socketState.activeRoomId, socketState.errorMessage);
              }
              if (socketState.latestEvent != null) {
                final eventConversationId = socketState.latestEvent!.conversationId ?? '';
                if (eventConversationId.isNotEmpty && eventConversationId != cubit.state.currentConversationId) {
                  return;
                }
                cubit.handleSocketEvent(socketState.latestEvent!);
              }
            },
          ),
          BlocListener<OutputPracticeCubit, OutputPracticeState>(
            listenWhen: (previous, current) => previous.inputText != current.inputText,
            listener: (context, state) {
              if (_controller.text == state.inputText) return;
              _controller.value = TextEditingValue(
                text: state.inputText,
                selection: TextSelection.collapsed(offset: state.inputText.length),
              );
            },
          ),
          BlocListener<OutputPracticeCubit, OutputPracticeState>(
            listener: (context, state) {
              final trackingData = _trackingData(state);
              if (!state.screenViewTracked && state.currentConversationId.isNotEmpty && trackingData != null) {
                AppService.instance.appTrackingService.trackOutputPracticeScrView(
                  trackingData,
                  sectionId: state.currentSectionId,
                  conversationId: state.currentConversationId,
                  language: AppDI.injector.get<LocaleCubit>().state.languageAISupport,
                  entryState: state.entryState.name,
                );
                context.read<OutputPracticeCubit>().markScreenViewTracked();
              }

              if (_scrollController.hasClients && state.isNearBottom) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                  }
                });
              }
            },
          ),
        ],
        child: BlocBuilder<OutputPracticeCubit, OutputPracticeState>(
          builder: (context, state) {
            final copy = context.l10n.outputPractice;
            final pageTitle = state.displayLesson.title.text.isNotEmpty ? state.displayLesson.title.text : copy.practiceLabel;
            return OutputPracticePageShell(
              header: OutputPracticeHeader(
                title: pageTitle,
                eyebrowText: _resolveHeaderEyebrow(state, copy),
                onClose: () => _handleClose(state),
              ),
              composer: OutputPracticeComposer(
                controller: _controller,
                enabled: state.isInputEnabled,
                placeholder: copy.inputPlaceholder,
                onChanged: context.read<OutputPracticeCubit>().updateInputText,
                onSend: () => _handleSend(state),
              ),
              child: state.uiMode == OutputPracticeUiMode.unavailable
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.w),
                        child: AppText(
                          state.unavailableMessage ?? copy.unavailableTitle,
                          textAlign: TextAlign.center,
                          style: AppStyle.text16.copyWith(color: AppCustomColor.textPrimary, height: 1.75),
                        ),
                      ),
                    )
                  : OutputPracticeTimelineList(
                      controller: _scrollController,
                      items: state.timelineItems,
                      activeActionChips: state.activeActionChips,
                      conversationTransitionStatus: state.conversationTransitionStatus,
                      assistantName: state.assistantNameOrFallback.isNotEmpty ? state.assistantNameOrFallback : copy.assistantName,
                      assistantAvatarUrl: state.assistantAvatarUrl,
                      userName: copy.userNameLabel,
                      helperLabel: state.isSummaryMode ? copy.followUpsLabel : copy.chooseNextStepLabel,
                      showThinking: state.isWaitingForSocket && !state.isStreaming,
                      thinkingLabel: copy.thinkingLabel,
                      historyErrorText: state.hasHistoryError ? copy.historyRetryTitle : null,
                      historyRetryLabel: copy.historyRetryButton,
                      onRetryHistory: () => context.read<OutputPracticeCubit>().retryHistory(),
                      roomErrorText: state.roomErrorMessage != null ? copy.roomRetryTitle : null,
                      roomRetryLabel: copy.roomRetryButton,
                      onRetryRoom: () => context.read<OutputPracticeSocketCubit>().reconnect(),
                      showJumpToLatest: state.showJumpToLatest,
                      jumpToLatestLabel: copy.jumpToLatestButton,
                      conversationTransitionLabel: copy.startingNewConversationLabel,
                      onJumpToLatest: () {
                        if (!_scrollController.hasClients) return;
                        _scrollController.animateTo(
                          _scrollController.position.maxScrollExtent,
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                        );
                        context.read<OutputPracticeCubit>().updateScrollState(isNearBottom: true);
                      },
                      onRetryFailedMessage: () => context.read<OutputPracticeCubit>().retryFailedMessage(),
                      onChipTap: (chip) {
                        final trackingData = _trackingData(state);
                        if (trackingData != null && state.currentConversationId.isNotEmpty) {
                          AppService.instance.appTrackingService.trackOutputPracticeOptionClick(
                            trackingData,
                            sectionId: state.currentSectionId,
                            conversationId: state.currentConversationId,
                            optionLabel: _resolveChipLabel(chip),
                            optionValue: chip.value,
                            inputSource: 'chip_tap',
                          );
                        }
                        context.read<OutputPracticeCubit>().sendActionChip(chip, committedText: _resolveChipLabel(chip));
                      },
                      resolveChipLabel: _resolveChipLabel,
                    ),
            );
          },
        ),
      ),
    );
  }
}
