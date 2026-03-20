part of '../../../../lesson.dart';

class LessonPageController {
  static const int _maxAutoScrollAttempts = 6;
  static const Duration _autoScrollDuration = Duration(milliseconds: 320);

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
  bool _didNotifyScroll = false;
  String _lastScrollKey = '';
  bool _didShowNavigationPopup = false;
  int _latestAutoScrollRequestId = 0;

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

  bool shouldTrackScroll(String scrollKey) {
    if (scrollKey == _lastScrollKey) return false;
    _lastScrollKey = scrollKey;
    return true;
  }

  bool handleUserScroll(UserScrollNotification notification, VoidCallback onTrackScroll) {
    if (notification.direction == ScrollDirection.idle) {
      _didNotifyScroll = false;
    } else if (!_didNotifyScroll) {
      _didNotifyScroll = true;
      onTrackScroll();
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

    _onBottomButtonVisibilityChanged(false);
    _scheduleBottomButtonVisibilityUpdate();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isMounted()) return;
      if (shouldSuppressAutoScroll) {
        _onClearSuppressNextAutoScroll();
        return;
      }
      _requestScrollToLastItem();
    });
  }

  void _requestScrollToLastItem() {
    _tryScrollToLastItem(requestId: ++_latestAutoScrollRequestId);
  }

  void _tryScrollToLastItem({
    required int requestId,
    int attempt = 0,
  }) {
    if (!_isMounted() || requestId != _latestAutoScrollRequestId) return;
    if (!scrollController.hasClients || !scrollController.position.hasContentDimensions) {
      _retryScrollToLastItem(requestId: requestId, attempt: attempt);
      return;
    }

    final position = scrollController.position;
    final targetContext = lastItemKey.currentContext;
    if (targetContext == null) {
      _scrollTowardsListEnd(
        requestId: requestId,
        attempt: attempt,
        fallbackOffset: position.maxScrollExtent,
      );
      return;
    }

    final renderObject = targetContext.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      _retryScrollToLastItem(requestId: requestId, attempt: attempt);
      return;
    }

    final viewport = RenderAbstractViewport.of(renderObject);
    final targetOffset = viewport.getOffsetToReveal(renderObject, 0).offset.clamp(position.minScrollExtent, position.maxScrollExtent).toDouble();
    if ((scrollController.offset - targetOffset).abs() <= 1.0) {
      _updateBottomButtonVisibility();
      return;
    }

    _animateToOffset(
      requestId: requestId,
      attempt: attempt,
      targetOffset: targetOffset,
    );
  }

  void _retryScrollToLastItem({
    required int requestId,
    required int attempt,
  }) {
    if (attempt >= _maxAutoScrollAttempts) {
      _scheduleBottomButtonVisibilityUpdate();
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isMounted() || requestId != _latestAutoScrollRequestId) return;
      _tryScrollToLastItem(requestId: requestId, attempt: attempt + 1);
    });
  }

  void _scrollTowardsListEnd({
    required int requestId,
    required int attempt,
    required double fallbackOffset,
  }) {
    final currentOffset = scrollController.offset;
    if ((fallbackOffset - currentOffset).abs() <= 1.0) {
      _retryScrollToLastItem(requestId: requestId, attempt: attempt);
      return;
    }

    _animateToOffset(
      requestId: requestId,
      attempt: attempt,
      targetOffset: fallbackOffset,
    );
  }

  void _animateToOffset({
    required int requestId,
    required int attempt,
    required double targetOffset,
  }) {
    scrollController
        .animateTo(
          targetOffset,
          duration: _autoScrollDuration,
          curve: Curves.easeOutCubic,
        )
        .whenComplete(() {
          if (!_isMounted() || requestId != _latestAutoScrollRequestId) return;
          _updateBottomButtonVisibility();
          if ((scrollController.offset - targetOffset).abs() > 1.0) {
            _retryScrollToLastItem(requestId: requestId, attempt: attempt + 1);
            return;
          }
          _retryScrollToLastItem(requestId: requestId, attempt: attempt);
        });
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
