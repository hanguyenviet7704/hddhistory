part of '../../../roleplay.dart';

class RoleplayContentList extends StatefulWidget {
  final RoleplayEntity roleplayData;

  const RoleplayContentList({super.key, required this.roleplayData});

  @override
  State<RoleplayContentList> createState() => _RoleplayContentListState();
}

class _RoleplayContentListState extends State<RoleplayContentList> {
  static const Duration _defaultDelay = Duration(seconds: 2);

  late GlobalKey<AnimatedListState> _listKey;
  final ScrollController _scrollController = ScrollController();
  final Map<int, RoleplayAudioController> _audioControllers = {};
  final List<int> _visibleIndexes = [];
  final Set<int> _completedExerciseIndexes = {};

  Completer<void>? _pendingExerciseCompleter;
  int? _pendingExerciseContentIndex;

  late List<RoleplayContentEntity> _displayableContents;
  bool _isSequencing = false;
  bool _isDisposing = false;

  @override
  void initState() {
    super.initState();
    _listKey = GlobalKey<AnimatedListState>();
    _configureContents();
    _updateSectionCompletion(_displayableContents.isEmpty);
    WidgetsBinding.instance.addPostFrameCallback((_) => _startSequence());
  }

  @override
  void didUpdateWidget(RoleplayContentList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.roleplayData.id != widget.roleplayData.id) {
      unawaited(_resetForNewSection());
    }
  }

  void _configureContents() {
    _cancelPendingExercise();
    _completedExerciseIndexes.clear();
    _displayableContents = widget.roleplayData.contents.toList();
    _prepareAudioControllers();
    _visibleIndexes.clear();
  }

  Future<void> _resetForNewSection() async {
    _cancelPendingExercise();
    await _disposeControllers();
    if (!mounted) return;
    setState(() {
      _listKey = GlobalKey<AnimatedListState>();
      _configureContents();
    });
    _updateSectionCompletion(_displayableContents.isEmpty);
    WidgetsBinding.instance.addPostFrameCallback((_) => _startSequence());
  }

  void _prepareAudioControllers() {
    _audioControllers.clear();

    for (var i = 0; i < _displayableContents.length; i++) {
      final content = _displayableContents[i];
      final String audioUrl = switch (content.type) {
        RoleplayContentType.conversation => content.conversation.audio.text,
        RoleplayContentType.leadingText => content.leadingText.audio.text,
        _ => '',
      };
      if (audioUrl.isNotEmpty) {
        _audioControllers[i] = RoleplayAudioController(audioUrl);
      }
    }
  }

  Future<void> _startSequence() async {
    if (_isSequencing) return;
    _isSequencing = true;

    try {
      while (!_isDisposing && mounted && _visibleIndexes.length < _displayableContents.length) {
        final bool shouldWaitForLastCompletion = _appendNextIndex();
        await _waitBeforeNext();
        if (_isDisposing || !mounted) return;
        if (shouldWaitForLastCompletion) {
          _updateSectionCompletion(true);
        }
      }
    } finally {
      _isSequencing = false;
    }
  }

  Future<void> _waitBeforeNext() async {
    if (_isDisposing) return;
    if (_visibleIndexes.isEmpty) return;

    final int currentIndex = _visibleIndexes.last;
    if (currentIndex < 0 || currentIndex >= _displayableContents.length) return;

    final content = _displayableContents[currentIndex];
    final RoleplayAudioController? controller = _audioControllers[currentIndex];

    switch (content.type) {
      case RoleplayContentType.exercise:
        if (!_isExerciseCompleted(currentIndex, content.exercise)) {
          await _showExerciseOverlayAndWait(contentIndex: currentIndex, exercise: content.exercise);
          return;
        }
        break;
      case RoleplayContentType.conversation:
      case RoleplayContentType.leadingText:
        if (controller != null && controller.hasAudio) {
          await controller.playAutoAndWait();
          return;
        }
        break;
      default:
        break;
    }

    await Future.delayed(_defaultDelay);
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_scrollController.hasClients) return;
    final double target = _scrollController.position.maxScrollExtent;
    if (animated) {
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(target);
    }
  }

  void _scheduleScrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollToBottom();
      Future<void>.delayed(const Duration(milliseconds: 250), () {
        if (!mounted) return;
        _scrollToBottom(animated: false);
      });
    });
  }

  void _updateSectionCompletion(bool isCompleted) {
    if (_isDisposing || !mounted) return;
    context.read<RoleplayCubit>().setCurrentSectionRevealed(isCompleted);
  }

  bool _isExerciseCompleted(int contentIndex, QuestionEntity exercise) {
    return exercise.isCompleted || _completedExerciseIndexes.contains(contentIndex);
  }

  Future<void> _showExerciseOverlayAndWait({
    required int contentIndex,
    required QuestionEntity exercise,
  }) async {
    _cancelPendingExercise();
    RoleplayExerciseResultOverlayManager.hide();
    _pendingExerciseContentIndex = contentIndex;
    _pendingExerciseCompleter = Completer<void>();

    RoleplayExerciseOverlayManager.show(
      context: context,
      builder: (_) => RoleplayExerciseOverlayInteractive(
        exercise: exercise,
        onCheckPressed: () => _handleExerciseCheckPressed(contentIndex),
      ),
      onOverlayShown: () {
        LearningItemEntity learningItem = LearningItemEntity(
          type: LearningItemType.roleplay,
          mainQuestions: [exercise],
        );
        AppDI.injector.get<ExerciseCubit>().setRoleplayQuestions(learningItem);
      },
    );

    await _pendingExerciseCompleter!.future;
  }

  void _handleExerciseCheckPressed(int contentIndex) {
    if (_isDisposing || !mounted) return;
    if (_pendingExerciseContentIndex != contentIndex) return;

    RoleplayExerciseResultOverlayManager.hide();
    RoleplayExerciseOverlayManager.hide();
    setState(() {
      _completedExerciseIndexes.add(contentIndex);
    });
    _scheduleScrollToBottom();
    _completePendingExercise();
  }

  void _completePendingExercise() {
    final completer = _pendingExerciseCompleter;
    _pendingExerciseCompleter = null;
    _pendingExerciseContentIndex = null;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  void _cancelPendingExercise() {
    RoleplayExerciseResultOverlayManager.hide();
    RoleplayExerciseOverlayManager.hide();
    _completePendingExercise();
  }

  bool _appendNextIndex() {
    final newIndex = _visibleIndexes.length;
    if (newIndex >= _displayableContents.length) return false;
    _visibleIndexes.add(newIndex);
    if (_listKey.currentState != null) {
      _listKey.currentState!.insertItem(newIndex, duration: const Duration(milliseconds: 250));
    }
    _scheduleScrollToBottom();
    if (_visibleIndexes.length != _displayableContents.length) {
      return false;
    }

    final RoleplayAudioController? lastController = _audioControllers[newIndex];

    final lastContent = _displayableContents[newIndex];
    if (lastContent.type == RoleplayContentType.exercise && !_isExerciseCompleted(newIndex, lastContent.exercise)) {
      return true;
    }

    if (lastController != null && lastController.hasAudio) {
      return true;
    }
    _updateSectionCompletion(true);
    return false;
  }

  @override
  void dispose() {
    _isDisposing = true;
    _cancelPendingExercise();
    unawaited(_disposeControllers());
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _disposeControllers() async {
    await Future.wait(_audioControllers.values.map((controller) => controller.dispose()));
    _audioControllers.clear();
  }

  bool _isSamePerson(ConversationEntity conversation, ConversationEntity? nextConversation) {
    if (nextConversation == null) return false;
    return nextConversation.avatar.id == conversation.avatar.id;
  }

  double _getBottomPadding(int index, int contentIndex) {
    if (index == _visibleIndexes.length - 1) return 0;
    final content = _displayableContents[contentIndex];
    if (content.type == RoleplayContentType.exercise && !_isExerciseCompleted(contentIndex, content.exercise)) {
      return 0;
    }
    if (content.type != RoleplayContentType.conversation) return 16.h;
    final nextConversation = contentIndex < _displayableContents.length - 1 ? _displayableContents[contentIndex + 1].conversation : null;
    if (_isSamePerson(content.conversation, nextConversation)) return 0;
    return 16.h;
  }

  @override
  Widget build(BuildContext context) {
    if (_displayableContents.isEmpty) {
      return ListView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
      );
    }

    return AnimatedList(
      key: _listKey,
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.zero,
      initialItemCount: _visibleIndexes.length,
      itemBuilder: (context, index, animation) {
        if (index >= _visibleIndexes.length) return const SizedBox.shrink();
        final contentIndex = _visibleIndexes[index];
        if (contentIndex >= _displayableContents.length) return const SizedBox.shrink();
        final content = _displayableContents[contentIndex];
        final previousConversation = contentIndex > 0 ? _displayableContents[contentIndex - 1].conversation : null;
        final audioController = _audioControllers[contentIndex];

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
          RoleplayContentType.exercise => RoleplayExerciseContentWidget(
            exercise: content.exercise,
            isCompleted: _isExerciseCompleted(contentIndex, content.exercise),
          ),
        };

        return SizeTransition(
          sizeFactor: animation,
          child: Padding(
            padding: EdgeInsets.only(bottom: _getBottomPadding(index, contentIndex)),
            child: child,
          ),
        );
      },
    );
  }
}
