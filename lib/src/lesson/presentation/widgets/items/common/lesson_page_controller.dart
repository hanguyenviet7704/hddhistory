part of '../../../../lesson.dart';

class LessonPageController {
  LessonPageController({
    required void Function(bool isVisible) onBottomButtonVisibilityChanged,
    required VoidCallback onClearSuppressNextAutoScroll,
    required bool Function() isMounted,
  }) : _onBottomButtonVisibilityChanged = onBottomButtonVisibilityChanged,
       _onClearSuppressNextAutoScroll = onClearSuppressNextAutoScroll,
       _isMounted = isMounted;

  final ScrollController scrollController = ScrollController();
  final GlobalKey lastItemKey = GlobalKey();

  final void Function(bool isVisible) _onBottomButtonVisibilityChanged;
  final VoidCallback _onClearSuppressNextAutoScroll;
  final bool Function() _isMounted;

  int _lastRenderedItemCount = 0;
  bool _didNotifyExerciseScroll = false;
  String _lastExerciseScrollKey = '';
  bool _didShowNavigationPopup = false;

  void handleEmptyItems() {
    _lastRenderedItemCount = 0;
    _scheduleBottomButtonVisibilityUpdate();
  }

  void showLessonNavigationPopupIfNeeded({
    required bool isFirstTime,
    required VoidCallback onMarkSeen,
    required VoidCallback onShowPopup,
  }) {
    if (_didShowNavigationPopup || !isFirstTime) return;
    _didShowNavigationPopup = true;
    onMarkSeen();
    onShowPopup();
  }

  bool shouldTrackExerciseScroll(String scrollKey) {
    if (scrollKey == _lastExerciseScrollKey) return false;
    _lastExerciseScrollKey = scrollKey;
    return true;
  }

  bool handleUserScroll(UserScrollNotification notification, VoidCallback onTrackExerciseScroll) {
    if (notification.direction == ScrollDirection.idle) {
      _didNotifyExerciseScroll = false;
    } else if (!_didNotifyExerciseScroll) {
      _didNotifyExerciseScroll = true;
      onTrackExerciseScroll();
    }
    _updateBottomButtonVisibility();
    return false;
  }

  void handleAutoScroll({
    required int itemCount,
    required bool shouldSuppressAutoScroll,
  }) {
    final previousCount = _lastRenderedItemCount;
    _lastRenderedItemCount = itemCount;
    if (itemCount < previousCount) {
      _scheduleBottomButtonVisibilityUpdate();
      return;
    }
    if (itemCount <= previousCount) return;

    _scheduleBottomButtonVisibilityUpdate();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isMounted()) return;
      if (shouldSuppressAutoScroll) {
        _onClearSuppressNextAutoScroll();
        return;
      }
      _scrollToLastItem();
    });
  }

  void _scrollToLastItem() {
    if (!scrollController.hasClients) return;
    final targetContext = lastItemKey.currentContext;
    if (targetContext == null) return;
    Scrollable.ensureVisible(
      targetContext,
      alignment: 0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    ).whenComplete(_updateBottomButtonVisibility);
  }

  void _scheduleBottomButtonVisibilityUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isMounted()) return;
      _updateBottomButtonVisibility();
    });
  }

  void _updateBottomButtonVisibility() {
    if (!_isMounted()) return;
    if (!scrollController.hasClients) return;
    final targetContext = lastItemKey.currentContext;
    if (targetContext == null) {
      _onBottomButtonVisibilityChanged(false);
      return;
    }

    final renderObject = targetContext.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;
    final viewport = RenderAbstractViewport.of(renderObject);
    final offset = scrollController.offset;
    final reveal = viewport.getOffsetToReveal(renderObject, 0);
    final itemTop = reveal.offset;
    final itemBottom = itemTop + renderObject.size.height;
    final viewportTop = offset;
    final viewportBottom = offset + scrollController.position.viewportDimension;
    final isVisible = itemBottom > viewportTop && itemTop < viewportBottom;
    _onBottomButtonVisibilityChanged(isVisible);
  }

  void dispose() {
    scrollController.dispose();
  }
}
