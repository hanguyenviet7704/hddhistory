part of '../../video_lesson.dart';

class _VideoLessonDraggableBottomSheetFrame extends StatefulWidget {
  const _VideoLessonDraggableBottomSheetFrame({
    required this.height,
    required this.onDismiss,
    required this.child,
    this.handleKey,
    this.dragRegionKey,
    this.header,
  });

  final double height;
  final VoidCallback onDismiss;
  final Widget child;
  final Key? handleKey;
  final Key? dragRegionKey;
  final Widget? header;

  @override
  State<_VideoLessonDraggableBottomSheetFrame> createState() => _VideoLessonDraggableBottomSheetFrameState();
}

class _VideoLessonDraggableBottomSheetFrameState extends State<_VideoLessonDraggableBottomSheetFrame> {
  static const _dismissThreshold = 72.0;
  static const _dismissVelocityThreshold = 900.0;

  double _dragOffsetY = 0;
  bool _isDragging = false;
  bool _isPresented = false;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _isPresented = true);
    });
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_isDismissing) return;
    setState(() {
      _isDragging = true;
      _dragOffsetY = max(0, _dragOffsetY + details.delta.dy);
    });
  }

  Future<void> _handleDragEnd(DragEndDetails details) async {
    final shouldDismiss = _dragOffsetY >= _dismissThreshold || (details.primaryVelocity ?? 0) > _dismissVelocityThreshold;
    if (shouldDismiss) {
      await _dismiss();
      return;
    }

    setState(() {
      _isDragging = false;
      _dragOffsetY = 0;
    });
  }

  Future<void> _dismiss() async {
    if (_isDismissing) return;

    setState(() {
      _isDismissing = true;
      _isDragging = false;
      _dragOffsetY = 0;
      _isPresented = false;
    });

    await Future<void>.delayed(_videoLessonFastAnimationDuration);
    if (mounted) widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final slideOffsetY = _dragOffsetY / max(widget.height, 1);
    final presentedOffset = _isPresented ? 0.0 : 1.04;
    final transitionDuration = _isDragging ? Duration.zero : _videoLessonMediumAnimationDuration;

    return Align(
      alignment: Alignment.bottomCenter,
      child: IgnorePointer(
        ignoring: _isDismissing,
        child: AnimatedOpacity(
          duration: transitionDuration,
          curve: _isPresented ? _videoLessonEntranceCurve : _videoLessonExitCurve,
          opacity: _isPresented ? 1 : 0,
          child: AnimatedScale(
            duration: transitionDuration,
            curve: _isPresented ? _videoLessonSpringCurve : _videoLessonExitCurve,
            scale: _isPresented ? 1 : 0.98,
            alignment: Alignment.bottomCenter,
            child: AnimatedSlide(
              duration: transitionDuration,
              curve: _isPresented ? _videoLessonSpringCurve : _videoLessonExitCurve,
              offset: Offset(0, presentedOffset + slideOffsetY),
              child: AnimatedContainer(
                duration: _videoLessonMediumAnimationDuration,
                curve: _videoLessonSpringCurve,
                width: double.infinity,
                height: widget.height,
                decoration: BoxDecoration(
                  color: AppCustomColor.backgroundWhite,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    GestureDetector(
                      key: widget.dragRegionKey,
                      behavior: HitTestBehavior.opaque,
                      onVerticalDragUpdate: _handleDragUpdate,
                      onVerticalDragEnd: _handleDragEnd,
                      child: Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(top: 10.h, bottom: 8.h),
                            child: Container(
                              key: widget.handleKey,
                              width: 44.w,
                              height: 4.h,
                              decoration: BoxDecoration(
                                color: AppCustomColor.borderDefault,
                                borderRadius: BorderRadius.circular(30.r),
                              ),
                            ),
                          ),
                          if (widget.header != null) widget.header!,
                        ],
                      ),
                    ),
                    Expanded(child: widget.child),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
