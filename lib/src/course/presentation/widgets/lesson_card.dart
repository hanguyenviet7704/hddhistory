part of '../../course.dart';

class LessonCard extends StatelessWidget {
  final LessonEntity lesson;
  final VoidCallback? onTap;

  const LessonCard({
    super.key,
    required this.lesson,
    this.onTap,
  });

  Color get _backgroundColor {
    switch (lesson.process) {
      case ProcessEnum.done:
        return AppCustomColor.backgroundWhite;
      case ProcessEnum.inProgress:
        return AppCustomColor.backgroundBrand;
      case ProcessEnum.notStarted:
        return AppCustomColor.backgroundGray;
    }
  }

  Color get _textColor {
    switch (lesson.process) {
      case ProcessEnum.done:
        return AppCustomColor.textPrimary;
      case ProcessEnum.inProgress:
        return AppCustomColor.brandPrimary300;
      case ProcessEnum.notStarted:
        return AppCustomColor.textQuaternary;
    }
  }

  Color? get _borderColor {
    if (lesson.process == ProcessEnum.done) {
      return AppCustomColor.borderDefault;
    }
    return null;
  }

  bool get _showInProgressBadge {
    return lesson.process == ProcessEnum.inProgress;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: lesson.process != ProcessEnum.notStarted ? onTap : null,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            constraints: BoxConstraints(minHeight: 44.h),
            decoration: BoxDecoration(
              color: _backgroundColor,
              borderRadius: BorderRadius.circular(12.r),
              border: _borderColor != null
                  ? Border.all(color: _borderColor!, width: 1)
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Lesson title
                AppText(
                  lesson.title.text,
                  style: AppStyle.text14.copyWith(
                    fontWeight: FontWeight.w500,
                    color: _textColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                8.verticalSpace,
                // Lesson metadata row
                Row(
                  children: [
                    // Lesson type
                    LessonMetadata(
                      icon: lesson.icon,
                      text: _getLessonTypeText(),
                      textColor: _textColor,
                    ),
                    12.horizontalSpace,
                    // Duration
                    if (lesson.estimateCompleTime.en.isNotEmpty)
                      LessonMetadata(
                        text: lesson.estimateCompleTime.text,
                        textColor: _textColor,
                      ),
                  ],
                ),
              ],
            ),
          ),
          // In Progress badge
          if (_showInProgressBadge)
            Positioned(
              top: -10.h,
              left: 16.w,
              child: const InProgressBadge(),
            ),
        ],
      ),
    );
  }

  String _getLessonTypeText() {
    switch (lesson.type) {
      case LessonType.lesson:
        return 'Lesson';
      case LessonType.entrance:
        return 'Entrance';
      case LessonType.output:
        return 'Output test';
    }
  }
}
