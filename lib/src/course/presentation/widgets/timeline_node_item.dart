part of '../../course.dart';

class TimelineLessonItem extends StatelessWidget {
  final LessonEntity lesson;
  final bool isLast;
  final VoidCallback? onTap;

  const TimelineLessonItem({
    super.key,
    required this.lesson,
    required this.isLast,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator column
          SizedBox(
            width: 24.w,
            child: Column(
              children: [
                // Node indicator circle
                Container(
                  width: 24.w,
                  height: 24.h,
                  decoration: BoxDecoration(
                    color: _getNodeCircleColor(),
                    shape: BoxShape.circle,
                    border: lesson.process == ProcessEnum.inProgress
                        ? Border.all(
                            color: AppCustomColor.brandPrimary,
                            width: 3.w,
                          )
                        : null,
                  ),
                  child: _getNodeIcon(),
                ),
                // Connector line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2.w,
                      color: AppCustomColor.borderSecondary,
                    ),
                  ),
              ],
            ),
          ),
          16.horizontalSpace,
          // Lesson card
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12.h),
              child: LessonCard(
                lesson: lesson,
                onTap: onTap,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getNodeCircleColor() {
    switch (lesson.process) {
      case ProcessEnum.done:
        return AppCustomColor.brandPrimary;
      case ProcessEnum.inProgress:
        return AppCustomColor.backgroundWhite;
      case ProcessEnum.notStarted:
        return AppCustomColor.borderSecondary;
    }
  }

  Widget? _getNodeIcon() {
    if (lesson.process == ProcessEnum.done) {
      return Icon(
        Icons.check_rounded,
        size: 16.w,
        color: AppCustomColor.backgroundWhite,
      );
    } else if (lesson.process == ProcessEnum.notStarted) {
      return Icon(
        Icons.lock_rounded,
        size: 14.w,
        color: AppCustomColor.textQuaternary,
      );
    }
    return null; // For in progress, just show empty circle with border
  }
}
