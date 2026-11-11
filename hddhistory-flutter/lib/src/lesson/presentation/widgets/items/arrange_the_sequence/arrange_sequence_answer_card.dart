part of '../../../../lesson.dart';

/// One draggable step on an arrange-the-sequence card (Keypoint v2 design).
///
/// Reordering stays a real drag via [ReorderableDragStartListener] — the design
/// prototype used tap-to-swap because it was driven by a mouse, but the app has
/// had proper drag-reorder since before this redesign and it is the better
/// affordance on touch.
///
/// Once graded, the row carries [correctPosition] rather than a bare tick or
/// cross: on a misplaced step that number is the whole correction.
class ArrangeSequenceAnswerCard extends StatelessWidget {
  final String text;
  final int index;
  final ArrangeAnswerState state;
  final bool dragEnabled;
  final bool isDragging;

  /// 1-based position this item belongs at. Only rendered once [state] is
  /// graded; null when the item couldn't be matched to the answer key.
  final int? correctPosition;

  const ArrangeSequenceAnswerCard({
    super.key,
    required this.text,
    required this.index,
    this.state = ArrangeAnswerState.normal,
    this.dragEnabled = true,
    this.isDragging = false,
    this.correctPosition,
  });

  bool get _isGraded => state != ArrangeAnswerState.normal;

  bool get _isCorrect => state == ArrangeAnswerState.correct;

  Color get _backgroundColor {
    if (isDragging || !_isGraded) return AppCustomColor.backgroundWhite;
    return _isCorrect ? AppCustomColor.kpCorrectSurface : AppCustomColor.kpWrongSurface;
  }

  Color get _borderColor {
    if (isDragging) return AppCustomColor.brandPrimary;
    if (!_isGraded) return AppCustomColor.kpOptionBorder;
    return _isCorrect ? AppCustomColor.kpCorrectBorder : AppCustomColor.kpWrongBorder;
  }

  Color get _handleColor {
    if (isDragging) return AppCustomColor.brandPrimary;
    if (!_isGraded) return AppCustomColor.kpArrangeHandle;
    return _isCorrect ? AppCustomColor.kpArrangeHandleCorrect : AppCustomColor.kpArrangeHandleWrong;
  }

  @override
  Widget build(BuildContext context) {
    final position = correctPosition;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: _backgroundColor,
          border: Border.all(color: _borderColor, width: 1.5),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: AppCustomColor.neutral01.withValues(alpha: isDragging ? 0.10 : 0.04),
              blurRadius: isDragging ? 18.r : 14.r,
              offset: Offset(0, isDragging ? 8.h : 4.h),
            ),
          ],
        ),
        child: ReorderableDragStartListener(
          index: index,
          enabled: dragEnabled,
          child: Row(
            children: [
              Icon(
                Icons.menu_rounded,
                color: _handleColor,
                size: 22.sp,
              ),
              12.horizontalSpace,
              Expanded(
                child: AppText(
                  text,
                  maxLines: 10,
                  style: AppStyle.text14.copyWith(
                    fontSize: 14.5.sp,
                    color: AppCustomColor.kpArrangeText,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
              if (_isGraded && position != null) ...[
                12.horizontalSpace,
                Container(
                  width: 20.w,
                  height: 20.w,
                  decoration: BoxDecoration(
                    color: _isCorrect ? AppCustomColor.successGreen : AppCustomColor.errorRed,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: AppText(
                    '$position',
                    style: AppStyle.text12.copyWith(
                      fontSize: 11.5.sp,
                      height: 1,
                      fontWeight: FontWeight.w800,
                      color: AppCustomColor.textWhite,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
