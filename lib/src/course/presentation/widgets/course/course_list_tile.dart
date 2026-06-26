part of '../../../course.dart';

class CourseListTile extends StatelessWidget {
  const CourseListTile({
    super.key,
    required this.course,
    this.isSelected = false,
    this.onTap,
  });

  final CourseEntity course;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: course.title.text,
      button: onTap != null,
      selected: isSelected,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: isSelected
                ? AppCustomColor.brandPrimary50
                : AppCustomColor.backgroundWhite,
            border: Border.all(
              color: isSelected
                  ? AppCustomColor.brandPrimary
                  : AppCustomColor.borderDefault,
            ),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: CacheNetworkGraphic(
                  url: course.image,
                  width: 64.w,
                  height: 64.w,
                  fit: BoxFit.cover,
                ),
              ),
              12.horizontalSpace,
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      course.title.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppStyle.textBold14.copyWith(
                        color: AppCustomColor.textPrimary,
                        height: 1.3,
                      ),
                    ),
                    6.verticalSpace,
                    _CourseProgressChip(course: course),
                  ],
                ),
              ),
              if (isSelected) ...[
                12.horizontalSpace,
                Container(
                  width: 24.w,
                  height: 24.w,
                  decoration: const BoxDecoration(
                    color: AppCustomColor.brandPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: AppCustomColor.backgroundWhite,
                    size: 14.w,
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

class _CourseProgressChip extends StatelessWidget {
  const _CourseProgressChip({required this.course});

  final CourseEntity course;

  @override
  Widget build(BuildContext context) {
    final progressState = context.watch<ProgressCubit>().state;
    final userProgress = progressState.userProgresses
        .firstWhereOrNull((p) => p.courseId == course.id);

    if (userProgress == null || userProgress.lessonsResult.isEmpty) {
      return AppText(
        context.l10n.allcourse.progressNotStarted,
        style: AppStyle.text12.copyWith(color: AppCustomColor.textTertiary),
      );
    }

    final completed =
        userProgress.lessonsResult.where((r) => r.passed).length;
    final total = course.numberOfLesson;

    if (total > 0 && completed >= total) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded,
              color: AppCustomColor.successGreen, size: 14.w),
          4.horizontalSpace,
          AppText(
            context.l10n.allcourse.progressCompleted,
            style:
                AppStyle.text12.copyWith(color: AppCustomColor.successGreen),
          ),
        ],
      );
    }

    final percent = (total > 0) ? (completed / total * 100).toInt() : 0;
    if (percent > 0) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14.w,
            height: 14.w,
            child: CircularProgressIndicator(
              value: total > 0 ? completed / total : 0,
              strokeWidth: 2.w,
              backgroundColor: AppCustomColor.borderDefault,
              color: AppCustomColor.brandPrimary,
            ),
          ),
          4.horizontalSpace,
          AppText(
            context.l10n.allcourse.progressPercent(percent: percent),
            style:
                AppStyle.text12.copyWith(color: AppCustomColor.brandPrimary),
          ),
        ],
      );
    }

    return AppText(
      context.l10n.allcourse.progressNotStarted,
      style: AppStyle.text12.copyWith(color: AppCustomColor.textTertiary),
    );
  }
}
