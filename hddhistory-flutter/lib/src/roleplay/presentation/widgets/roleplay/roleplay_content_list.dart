part of '../../../roleplay.dart';

class RoleplayContentList extends StatefulWidget {
  const RoleplayContentList({super.key});

  @override
  State<RoleplayContentList> createState() => _RoleplayContentListState();
}

class _RoleplayContentListState extends State<RoleplayContentList> {
  late GlobalKey<AnimatedListState> _listKey;
  final ScrollController _scrollController = ScrollController();
  late final RoleplayContentController _controller;
  bool _hasTrackedConvScroll = false;
  bool _hasTrackedConvScrollBottom = false;

  @override
  void initState() {
    super.initState();
    _listKey = GlobalKey<AnimatedListState>();
    _scrollController.addListener(_handleScroll);
    _controller = RoleplayContentController(
      onInsertItem: (index) {
        _listKey.currentState?.insertItem(index, duration: const Duration(milliseconds: 350));
      },
      onScheduleScrollToBottom: _scheduleScrollToBottom,
      onShowExerciseOverlay: _showExerciseOverlay,
      onHideOverlays: () {
        RoleplayExerciseOverlayManager.hide();
      },
      onSectionCompletionChanged: (isCompleted) {
        if (!mounted) return;
        context.read<RoleplayCubit>().setCurrentSectionRevealed(isCompleted);
      },
    );
    _controller.configure();
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.startSequence());
  }

  Future<void> _resetForNewSection() async {
    if (!mounted) return;
    await _controller.reset();
    if (!mounted) return;
    setState(() => _listKey = GlobalKey<AnimatedListState>());
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.startSequence());
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final distanceFromBottom = position.maxScrollExtent - position.pixels;
    _controller.handleScroll(
      distanceFromBottom: distanceFromBottom,
      direction: position.userScrollDirection,
    );
    _trackConversationScroll(position);
  }

  void _trackConversationScroll(ScrollPosition position) {
    final trackingData = RoleplayTrackingData.fromContext();
    if (trackingData == null) return;
    final haveQuiz = _hasQuiz() ? 'yes' : 'no';

    if (!_hasTrackedConvScroll && position.userScrollDirection != ScrollDirection.idle) {
      AppService.instance.appTrackingService.trackRoleplayConvScroll(
        trackingData,
        haveQuiz: haveQuiz,
      );
      _hasTrackedConvScroll = true;
    }

    if (!_hasTrackedConvScrollBottom && position.pixels >= position.maxScrollExtent - 16) {
      AppService.instance.appTrackingService.trackRoleplayConvScroll(
        trackingData,
        haveQuiz: haveQuiz,
      );
      _hasTrackedConvScrollBottom = true;
    }
  }

  bool _hasQuiz() {
    final contents = context.read<RoleplayCubit>().state.currentRoleplay.contents;
    return contents.any((content) => content.type == RoleplayContentType.exercise);
  }

  bool _shouldResetForPrefill(RoleplayState current) {
    final lastCompletedIndex = current.currentRoleplay.lastFinishedExerciseIndex;
    if (lastCompletedIndex < 0) return false;
    if (_controller.visibleIndexes.length >= lastCompletedIndex + 1) return false;
    return true;
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_scrollController.hasClients) return;
    final double target = _scrollController.position.maxScrollExtent;
    if (animated) {
      _controller.setAutoScrolling(true);
      _scrollController
          .animateTo(
            target,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          )
          .whenComplete(() => _controller.setAutoScrolling(false));
    } else {
      _controller.setAutoScrolling(true);
      _scrollController.jumpTo(target);
      _controller.setAutoScrolling(false);
    }
  }

  /// Schedules scroll to bottom after animation completes.
  /// Waits for SizeTransition animation (350ms) plus buffer to ensure
  /// the last widget is fully laid out before calculating maxScrollExtent.
  void _scheduleScrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // Wait for SizeTransition animation to complete (350ms + 50ms buffer)
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  bool _isSamePerson(ConversationEntity conversation, ConversationEntity? nextConversation) {
    if (nextConversation == null) return false;
    return nextConversation.avatar.id == conversation.avatar.id;
  }

  double _getBottomPadding(int index, int contentIndex, List<RoleplayContentEntity> contents) {
    if (index == _controller.visibleIndexes.length - 1) return 0;
    if (contentIndex < 0 || contentIndex >= contents.length) return 0;
    final content = contents[contentIndex];
    if (content.type == RoleplayContentType.exercise && !_controller.isExerciseCompleted(contentIndex, content.exercise)) {
      return 0;
    }
    if (content.type != RoleplayContentType.conversation) return 16.h;
    final nextConversation = contentIndex < contents.length - 1 ? contents[contentIndex + 1].conversation : null;
    if (_isSamePerson(content.conversation, nextConversation)) return 0;
    return 16.h;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RoleplayCubit, RoleplayState>(
      listenWhen: (previous, current) =>
          previous.currentRoleplay.id != current.currentRoleplay.id ||
          previous.currentRoleplay.contents.length != current.currentRoleplay.contents.length ||
          _shouldResetForPrefill(current),
      listener: (context, state) {
        _hasTrackedConvScroll = false;
        _hasTrackedConvScrollBottom = false;
        unawaited(_resetForNewSection());
      },
      child: BlocBuilder<RoleplayCubit, RoleplayState>(
        buildWhen: (previous, current) => previous.currentRoleplay != current.currentRoleplay,
        builder: (context, state) {
          final contents = state.currentRoleplay.contents.toList();
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              if (contents.isEmpty) {
                return ListView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                );
              }

              return AnimatedList(
                key: _listKey,
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: _controller.isOverlayVisible ? EdgeInsets.only(bottom: 175.h) : EdgeInsets.zero,
                initialItemCount: _controller.visibleIndexes.length,
                itemBuilder: (context, index, animation) {
                  final curvedAnimation = CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  );
                  if (index >= _controller.visibleIndexes.length) return const SizedBox.shrink();
                  final contentIndex = _controller.visibleIndexes[index];
                  if (contentIndex >= contents.length) return const SizedBox.shrink();
                  final content = contents[contentIndex];
                  final previousConversation = contentIndex > 0 ? contents[contentIndex - 1].conversation : null;
                  final audioController = _controller.audioControllerAt(contentIndex);

                  final Widget child = switch (content.type) {
                    RoleplayContentType.conversation => RoleplayConversationBubble(
                      conversation: content.conversation,
                      previousConversation: previousConversation,
                      audioController: audioController,
                    ),
                    RoleplayContentType.leadingText => RoleplayLeadingText(
                      leadingText: content.leadingText,
                      audioController: audioController,
                    ),
                    RoleplayContentType.transition => RoleplayTransitionText(transition: content.transition),
                    RoleplayContentType.exercise => KeyedSubtree(
                      key: ValueKey('${contentIndex}_${content.exercise.result.hashCode}'),
                      child: RoleplayExerciseContentWidget(
                        exercise: content.exercise,
                        isCompleted: _controller.isExerciseCompleted(contentIndex, content.exercise),
                        onTapResult: _controller.isExerciseCompleted(contentIndex, content.exercise) ? () => _showResultOverlay(contentIndex, content.exercise) : null,
                      ),
                    ),
                    RoleplayContentType.unknown => const SizedBox.shrink(),
                  };

                  return SizeTransition(
                    sizeFactor: curvedAnimation,
                    child: FadeTransition(
                      opacity: curvedAnimation,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: _getBottomPadding(index, contentIndex, contents)),
                        child: child,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  List<RoleplayContentEntity> _currentContents() {
    return context.read<RoleplayCubit>().state.currentRoleplay.contents.toList();
  }

  void _showExerciseOverlay({
    required int contentIndex,
    required QuestionEntity exercise,
    required VoidCallback onCheckPressed,
  }) {
    final contents = _currentContents();
    RoleplayExerciseOverlayManager.show(
      context: context,
      builder: (_) => RoleplayExerciseOverlayInteractive(
        exercise: exercise,
        contentId: contentIndex >= 0 && contentIndex < contents.length ? contents[contentIndex].id : 0,
        contentIndex: contentIndex,
        onCheckPressed: onCheckPressed,
      ),
      onOverlayShown: () {
        LearningItemEntity learningItem = LearningItemEntity(
          type: LearningItemType.roleplay,
          mainQuestions: [exercise],
        );
        AppDI.injector.get<ExerciseCubit>().setRoleplayQuestions(learningItem);
      },
    );
  }

  void _showResultOverlay(int contentIndex, QuestionEntity exercise) {
    if (_controller.isOverlayVisible) return;
    _controller.stopAllAudio();
    _controller.setOverlayVisible(true);

    RoleplayExerciseOverlayManager.show(
      context: context,
      builder: (_) => RoleplayExerciseOverlayInteractive(
        exercise: exercise,
        contentId: _currentContentId(contentIndex),
        contentIndex: contentIndex,
        readOnly: true,
        result: exercise.result,
        onDismissed: () => _controller.setOverlayVisible(false),
        onCheckPressed: () {
          RoleplayExerciseOverlayManager.hide();
          _controller.setOverlayVisible(false);
        },
      ),
      onOverlayShown: () {},
    );
  }

  int _currentContentId(int contentIndex) {
    final contents = _currentContents();
    if (contentIndex < 0 || contentIndex >= contents.length) return 0;
    return contents[contentIndex].id;
  }
}
