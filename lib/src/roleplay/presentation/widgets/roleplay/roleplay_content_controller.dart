part of '../../../roleplay.dart';

typedef RoleplayExerciseOverlayPresenter =
    void Function({
      required int contentIndex,
      required QuestionEntity exercise,
      required VoidCallback onCheckPressed,
    });

class RoleplayContentController extends ChangeNotifier {
  RoleplayContentController({
    required RoleplayExerciseOverlayPresenter onShowExerciseOverlay,
    required VoidCallback onHideOverlays,
    required VoidCallback onScheduleScrollToBottom,
    required void Function(int index) onInsertItem,
    required void Function(bool isCompleted) onSectionCompletionChanged,
  }) : _onShowExerciseOverlay = onShowExerciseOverlay,
       _onHideOverlays = onHideOverlays,
       _onScheduleScrollToBottom = onScheduleScrollToBottom,
       _onInsertItem = onInsertItem,
       _onSectionCompletionChanged = onSectionCompletionChanged;

  static const Duration _defaultDelay = Duration(seconds: 2);

  final RoleplayExerciseOverlayPresenter _onShowExerciseOverlay;
  final VoidCallback _onHideOverlays;
  final VoidCallback _onScheduleScrollToBottom;
  final void Function(int index) _onInsertItem;
  final void Function(bool isCompleted) _onSectionCompletionChanged;

  final Map<int, RoleplayAudioController> _audioControllers = {};
  final List<int> _visibleIndexes = [];
  final Set<int> _completedExerciseIndexes = {};
  int _sequenceToken = 0;

  Completer<void>? _pendingExerciseCompleter;
  int? _pendingExerciseContentIndex;
  Completer<void>? _overlayHiddenCompleter;
  int _delayToken = 0;
  bool _isDelayPending = false;
  bool _restartDelayAfterOverlay = false;
  bool _isSequencing = false;
  bool _isDisposing = false;
  bool _shouldAutoScroll = true;
  bool _isAutoScrolling = false;
  bool _isOverlayVisible = false;
  static const double _autoScrollThreshold = 80;

  List<int> get visibleIndexes => _visibleIndexes;
  bool get isOverlayVisible => _isOverlayVisible;

  RoleplayAudioController? audioControllerAt(int index) => _audioControllers[index];

  void stopAllAudio() {
    for (final controller in _audioControllers.values) {
      unawaited(controller.stop());
    }
  }

  bool isExerciseCompleted(int contentIndex, QuestionEntity exercise) {
    return exercise.hasResult || exercise.isCompleted || _completedExerciseIndexes.contains(contentIndex);
  }

  void setOverlayVisible(bool isVisible) {
    if (_isOverlayVisible == isVisible) return;
    _isOverlayVisible = isVisible;
    if (isVisible) {
      _overlayHiddenCompleter ??= Completer<void>();
      if (_isDelayPending) {
        _delayToken++;
        _isDelayPending = false;
        _restartDelayAfterOverlay = true;
      }
    } else {
      final completer = _overlayHiddenCompleter;
      _overlayHiddenCompleter = null;
      if (completer != null && !completer.isCompleted) {
        completer.complete();
      }
      if (_restartDelayAfterOverlay) {
        _restartDelayAfterOverlay = false;
        final contentIndex = _pendingExerciseContentIndex;
        if (contentIndex != null) {
          _completePendingExerciseWithDelay(contentIndex);
        }
      }
    }
    notifyListeners();
  }

  Future<void> waitForOverlayHidden() async {
    if (!_isOverlayVisible) return;
    _overlayHiddenCompleter ??= Completer<void>();
    await _overlayHiddenCompleter!.future;
  }

  void handleScroll({
    required double distanceFromBottom,
    required ScrollDirection direction,
  }) {
    if (_isAutoScrolling) return;
    if (distanceFromBottom <= _autoScrollThreshold) {
      _shouldAutoScroll = true;
      return;
    }

    if (direction == ScrollDirection.forward) {
      _shouldAutoScroll = false;
    }
  }

  void setAutoScrolling(bool value) {
    _isAutoScrolling = value;
  }

  void configure() {
    _cancelPendingExercise();
    _invalidateSequence();
    _initializeForContents(_currentContents());
  }

  Future<void> reset() async {
    _cancelPendingExercise();
    _invalidateSequence();
    await _disposeControllers();
    _initializeForContents(_currentContents());
  }

  void _initializeForContents(List<RoleplayContentEntity> contents) {
    _visibleIndexes.clear();
    _completedExerciseIndexes.clear();
    _shouldAutoScroll = true;
    _prepareAudioControllers(contents);
    _applyPrefill(AppDI.injector.get<RoleplayCubit>().state.currentRoleplay);
    notifyListeners();
  }

  Future<void> startSequence() async {
    if (_isSequencing) return;
    final int token = ++_sequenceToken;
    _isSequencing = true;

    try {
      while (!_isDisposing && token == _sequenceToken && _visibleIndexes.length < _currentContents().length) {
        final bool shouldWaitForLastCompletion = _appendNextIndex();
        await _waitBeforeNext(token);
        if (_isDisposing || token != _sequenceToken) return;
        if (shouldWaitForLastCompletion) {
          _updateSectionCompletion(true);
        }
      }
    } finally {
      if (token == _sequenceToken) {
        _isSequencing = false;
      }
    }
  }

  void markExerciseCompleted(int contentIndex) {
    if (_completedExerciseIndexes.add(contentIndex)) {
      notifyListeners();
    }
  }

  Future<void> _waitBeforeNext(int token) async {
    if (_isDisposing) return;
    if (token != _sequenceToken) return;
    if (_visibleIndexes.isEmpty) return;

    final int currentIndex = _visibleIndexes.last;
    final contents = _currentContents();
    if (currentIndex < 0 || currentIndex >= contents.length) return;

    final content = contents[currentIndex];
    final RoleplayAudioController? controller = _audioControllers[currentIndex];

    switch (content.type) {
      case RoleplayContentType.exercise:
        if (!isExerciseCompleted(currentIndex, content.exercise)) {
          await _showExerciseOverlayAndWait(
            contentIndex: currentIndex,
            exercise: content.exercise,
          );
          return;
        }
        break;
      case RoleplayContentType.conversation:
      case RoleplayContentType.leadingText:
        if (controller != null && controller.hasAudio) {
          await controller.playAutoAndWait();
          if (token != _sequenceToken) return;
          return;
        }
        break;
      default:
        break;
    }

    await Future.delayed(_defaultDelay);
  }

  bool _appendNextIndex() {
    final newIndex = _visibleIndexes.length;
    final contents = _currentContents();
    if (newIndex >= contents.length) return false;
    _visibleIndexes.add(newIndex);
    _onInsertItem(newIndex);
    _requestAutoScroll();
    notifyListeners();

    if (_visibleIndexes.length != contents.length) {
      return false;
    }

    final RoleplayAudioController? lastController = _audioControllers[newIndex];
    final lastContent = contents[newIndex];

    if (lastContent.type == RoleplayContentType.exercise && !isExerciseCompleted(newIndex, lastContent.exercise)) {
      return true;
    }

    if (lastController != null && lastController.hasAudio) {
      return true;
    }

    _updateSectionCompletion(true);
    return false;
  }

  Future<void> _showExerciseOverlayAndWait({
    required int contentIndex,
    required QuestionEntity exercise,
  }) async {
    if (_isOverlayVisible) {
      await waitForOverlayHidden();
      if (_isDisposing) return;
    }
    _cancelPendingExercise();
    _pendingExerciseContentIndex = contentIndex;
    _pendingExerciseCompleter = Completer<void>();
    setOverlayVisible(true);

    _onShowExerciseOverlay(
      contentIndex: contentIndex,
      exercise: exercise,
      onCheckPressed: () => handleExerciseCheckPressed(
        contentIndex: contentIndex,
        exercise: exercise,
      ),
    );

    await _pendingExerciseCompleter!.future;
  }

  void handleExerciseCheckPressed({
    required int contentIndex,
    required QuestionEntity exercise,
  }) {
    if (_isDisposing) return;
    if (_pendingExerciseContentIndex != contentIndex) return;

    final payload = exercise.typedPayload;
    final shouldSetQuestionPoint = payload is! QuestionSpeakingPayloadEntity && payload is! QuestionUnsupportedPayloadEntity;
    if (shouldSetQuestionPoint) {
      AppDI.injector.get<ExerciseCubit>().setQuestionPoint(exercise);
    }
    _onHideOverlays();
    _completedExerciseIndexes.add(contentIndex);
    setOverlayVisible(false);
    _requestAutoScroll();
    _completePendingExerciseWithDelay(contentIndex);
  }

  void _completePendingExerciseWithDelay(int contentIndex) {
    final bool shouldDelay = _visibleIndexes.length < _currentContents().length;
    if (!shouldDelay) {
      _completePendingExercise();
      return;
    }

    final int token = ++_delayToken;
    _isDelayPending = true;
    unawaited(_delayAndComplete(contentIndex, token));
  }

  Future<void> _delayAndComplete(int contentIndex, int token) async {
    await Future.delayed(_defaultDelay);
    if (_isDisposing) return;
    if (token != _delayToken) return;
    if (_pendingExerciseContentIndex != contentIndex) return;
    if (_isOverlayVisible) return;
    _isDelayPending = false;
    _completePendingExercise();
  }

  void _completePendingExercise() {
    final completer = _pendingExerciseCompleter;
    _pendingExerciseCompleter = null;
    _pendingExerciseContentIndex = null;
    _isDelayPending = false;
    _restartDelayAfterOverlay = false;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  void _cancelPendingExercise() {
    _onHideOverlays();
    setOverlayVisible(false);
    _completePendingExercise();
  }

  void _updateSectionCompletion(bool isCompleted) {
    if (_isDisposing) return;
    _onSectionCompletionChanged(isCompleted);
  }

  void _invalidateSequence() {
    _sequenceToken++;
    _isSequencing = false;
  }

  void _applyPrefill(RoleplayEntity roleplay) {
    final contents = roleplay.contents;
    if (contents.isEmpty) {
      _updateSectionCompletion(true);
      return;
    }

    for (var i = 0; i < contents.length; i++) {
      final content = contents[i];
      if (content.type == RoleplayContentType.exercise && content.exercise.hasResult) {
        _completedExerciseIndexes.add(i);
      }
    }

    final int lastCompletedIndex = roleplay.lastFinishedExerciseIndex;
    if (lastCompletedIndex < 0) {
      _updateSectionCompletion(false);
      return;
    }

    for (var i = 0; i <= lastCompletedIndex && i < contents.length; i++) {
      _visibleIndexes.add(i);
    }

    final bool allVisible = _visibleIndexes.length == contents.length;
    _updateSectionCompletion(allVisible && _isLastContentCompleted(contents));
  }

  bool _isLastContentCompleted(List<RoleplayContentEntity> contents) {
    if (contents.isEmpty) return true;
    final lastIndex = contents.length - 1;
    final lastContent = contents[lastIndex];
    if (lastContent.type == RoleplayContentType.exercise) {
      return isExerciseCompleted(lastIndex, lastContent.exercise);
    }
    return true;
  }

  void _requestAutoScroll() {
    if (_shouldAutoScroll) {
      _onScheduleScrollToBottom();
    }
  }

  List<RoleplayContentEntity> _currentContents() {
    return AppDI.injector.get<RoleplayCubit>().state.currentRoleplay.contents.toList();
  }

  void _prepareAudioControllers(List<RoleplayContentEntity> contents) {
    _audioControllers.clear();

    for (var i = 0; i < contents.length; i++) {
      final content = contents[i];
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

  Future<void> _disposeControllers() async {
    await Future.wait(_audioControllers.values.map((controller) => controller.dispose()));
    _audioControllers.clear();
  }

  @override
  void dispose() {
    _isDisposing = true;
    _cancelPendingExercise();
    unawaited(_disposeControllers());
    super.dispose();
  }
}
