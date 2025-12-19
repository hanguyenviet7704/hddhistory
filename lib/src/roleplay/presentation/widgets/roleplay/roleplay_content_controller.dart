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
  List<RoleplayContentEntity> _displayableContents = [];

  Completer<void>? _pendingExerciseCompleter;
  int? _pendingExerciseContentIndex;
  bool _isSequencing = false;
  bool _isDisposing = false;
  bool _shouldAutoScroll = true;
  bool _isAutoScrolling = false;
  static const double _autoScrollThreshold = 80;

  List<RoleplayContentEntity> get displayableContents => _displayableContents;
  List<int> get visibleIndexes => _visibleIndexes;

  RoleplayAudioController? audioControllerAt(int index) => _audioControllers[index];

  bool isExerciseCompleted(int contentIndex, QuestionEntity exercise) {
    return exercise.isCompleted || _completedExerciseIndexes.contains(contentIndex);
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

  void configure(List<RoleplayContentEntity> contents) {
    _cancelPendingExercise();
    _completedExerciseIndexes.clear();
    _displayableContents = contents.toList();
    _shouldAutoScroll = true;
    _prepareAudioControllers();
    _visibleIndexes.clear();
    _updateSectionCompletion(_displayableContents.isEmpty);
    notifyListeners();
  }

  Future<void> reset(List<RoleplayContentEntity> contents) async {
    _cancelPendingExercise();
    await _disposeControllers();
    _displayableContents = contents.toList();
    _visibleIndexes.clear();
    _completedExerciseIndexes.clear();
    _shouldAutoScroll = true;
    _prepareAudioControllers();
    _updateSectionCompletion(_displayableContents.isEmpty);
    notifyListeners();
  }

  Future<void> startSequence() async {
    if (_isSequencing) return;
    _isSequencing = true;

    try {
      while (!_isDisposing && _visibleIndexes.length < _displayableContents.length) {
        final bool shouldWaitForLastCompletion = _appendNextIndex();
        await _waitBeforeNext();
        if (_isDisposing) return;
        if (shouldWaitForLastCompletion) {
          _updateSectionCompletion(true);
        }
      }
    } finally {
      _isSequencing = false;
    }
  }

  void markExerciseCompleted(int contentIndex) {
    if (_completedExerciseIndexes.add(contentIndex)) {
      notifyListeners();
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
    if (newIndex >= _displayableContents.length) return false;
    _visibleIndexes.add(newIndex);
    _onInsertItem(newIndex);
    _requestAutoScroll();
    notifyListeners();

    if (_visibleIndexes.length != _displayableContents.length) {
      return false;
    }

    final RoleplayAudioController? lastController = _audioControllers[newIndex];
    final lastContent = _displayableContents[newIndex];

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
    _cancelPendingExercise();
    _pendingExerciseContentIndex = contentIndex;
    _pendingExerciseCompleter = Completer<void>();

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

    AppDI.injector.get<ExerciseCubit>().setQuestionPoint(exercise);
    _onHideOverlays();
    _completedExerciseIndexes.add(contentIndex);
    notifyListeners();
    _requestAutoScroll();
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
    _onHideOverlays();
    _completePendingExercise();
  }

  void _updateSectionCompletion(bool isCompleted) {
    if (_isDisposing) return;
    _onSectionCompletionChanged(isCompleted);
  }

  void _requestAutoScroll() {
    if (_shouldAutoScroll) {
      _onScheduleScrollToBottom();
    }
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
