part of '../../../../lesson.dart';

class ArrangeSequenceAnswerCard extends StatelessWidget {
  final String text;
  final int index;
  final ArrangeAnswerState state;
  final bool dragEnabled;
  final bool isDragging;

  const ArrangeSequenceAnswerCard({
    super.key,
    required this.text,
    required this.index,
    this.state = ArrangeAnswerState.normal,
    this.dragEnabled = true,
    this.isDragging = false,
  });

  Color get _backgroundColor {
    if (isDragging) return Colors.white;
    return switch (state) {
      ArrangeAnswerState.correct => AppCustomColor.backgroundSuccess,
      ArrangeAnswerState.incorrect => AppCustomColor.backgroundError,
      _ => Colors.white,
    };
  }

  Color get _borderColor {
    if (isDragging) return AppCustomColor.textSecondary;
    return switch (state) {
      ArrangeAnswerState.correct => AppCustomColor.successGreen,
      ArrangeAnswerState.incorrect => AppCustomColor.errorRed,
      _ => AppCustomColor.borderSecondary,
    };
  }

  Widget? get _statusIcon {
    if (isDragging) return null;
    return switch (state) {
      ArrangeAnswerState.correct => _buildStatusIcon(AppCustomColor.successGreen, Icons.check_rounded),
      ArrangeAnswerState.incorrect => _buildStatusIcon(AppCustomColor.errorRed, Icons.close_rounded),
      _ => null,
    };
  }

  Widget _buildStatusIcon(Color bgColor, IconData icon) {
    return Container(
      width: 20.w,
      height: 20.h,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Icon(
        icon,
        size: 14.sp,
        color: Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = AppCustomColor.greyCD.withValues(alpha: dragEnabled ? 1 : 0.6);

    return Material(
      color: Colors.transparent,
      elevation: isDragging ? 4 : 0,
      shadowColor: isDragging ? Colors.black.withValues(alpha: 0.08) : Colors.transparent,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: _backgroundColor,
          border: Border.all(
            color: _borderColor,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: ReorderableDragStartListener(
          index: index,
          enabled: dragEnabled,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.menu_rounded,
                color: iconColor,
                size: 24.sp,
              ),
              8.horizontalSpace,
              Expanded(
                child: AppText(
                  text,
                  maxLines: 10,
                  style: AppStyle.text14.copyWith(
                    color: AppCustomColor.textSecondary,
                    fontWeight: FontWeight.w500,
                    height: 1.75,
                  ),
                ),
              ),
              if (_statusIcon != null) ...[
                10.horizontalSpace,
                _statusIcon!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
