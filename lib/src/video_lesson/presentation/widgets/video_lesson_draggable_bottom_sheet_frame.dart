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

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _isDragging = true;
      _dragOffsetY = max(0, _dragOffsetY + details.delta.dy);
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    final shouldDismiss = _dragOffsetY >= _dismissThreshold || (details.primaryVelocity ?? 0) > _dismissVelocityThreshold;
    if (shouldDismiss) {
      widget.onDismiss();
      return;
    }

    setState(() {
      _isDragging = false;
      _dragOffsetY = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final slideOffsetY = _dragOffsetY / max(widget.height, 1);

    return Align(
      alignment: Alignment.bottomCenter,
      child: AnimatedSlide(
        duration: _isDragging ? Duration.zero : const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        offset: Offset(0, slideOffsetY),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
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
    );
  }
}
