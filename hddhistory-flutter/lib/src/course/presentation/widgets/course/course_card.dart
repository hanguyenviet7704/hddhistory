part of '../../../course.dart';

class CourseCard extends StatelessWidget {
  final CourseEntity course;
  final bool showProgress;
  final int? completedLessons;
  final int? totalLessons;
  final bool isSelected;
  final VoidCallback onTap;

  const CourseCard({
    super.key,
    required this.course,
    this.showProgress = false,
    this.completedLessons,
    this.totalLessons,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        AppHaptic.select();
        onTap();
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppCustomColor.brandPrimary : AppCustomColor.borderDefault,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16.r),
        ),
        padding: EdgeInsets.all(8.w),
        child: Row(
          children: [
            // Course image with badge overlay
            Stack(
              children: [
                CacheNetworkGraphic(
                  url: course.image,
                  width: 80.w,
                  height: 80.w,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                Positioned(
                  top: 4.h,
                  left: 4.w,
                  child: _CourseBadge(
                    course: course,
                    completedLessons: completedLessons,
                    totalLessons: totalLessons,
                  ),
                ),
              ],
            ),
            16.horizontalSpace,
            // Course info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppText(
                    course.title.text,
                    style: AppStyle.text16.copyWith(
                      color: AppCustomColor.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  8.verticalSpace,
                  if (showProgress && completedLessons != null && totalLessons != null) _buildProgressView(context) else _buildLessonCountView(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressView(BuildContext context) {
    final progress = totalLessons! > 0 ? completedLessons! / totalLessons! : 0.0;

    return Row(
      children: [
        Container(
          width: 60.w,
          height: 6.h,
          decoration: BoxDecoration(
            color: AppCustomColor.borderSecondary,
            borderRadius: BorderRadius.circular(18.r),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: AppCustomColor.textPrimary,
                borderRadius: BorderRadius.circular(18.r),
              ),
            ),
          ),
        ),
        6.horizontalSpace,
        AppText(
          context.l10n.allcourse.lessonsProgress(completed: completedLessons!, total: totalLessons!),
          style: AppStyle.text12.copyWith(
            color: AppCustomColor.textTertiary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLessonCountView(BuildContext context) {
    return Row(
      children: [
        SvgPicture.asset(AppAsset.svg.app.icBook, width: 16.w),
        8.horizontalSpace,
        AppText(
          context.l10n.allcourse.lessonsCount(count: course.numberOfLesson),
          style: AppStyle.text12.copyWith(
            color: AppCustomColor.textTertiary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Badge shown in the top-left corner of a course thumbnail.
/// Priority: comingSoon > isNew > in-progress percent > (nothing for not started).
class _CourseBadge extends StatelessWidget {
  const _CourseBadge({
    required this.course,
    this.completedLessons,
    this.totalLessons,
  });

  final CourseEntity course;
  final int? completedLessons;
  final int? totalLessons;

  @override
  Widget build(BuildContext context) {
    if (course.status == CoursePublishStatus.comingSoon) {
      return _BadgeChip(
        label: context.l10n.allcourse.comingSoonLabel,
        backgroundColor: AppCustomColor.brandPrimary700,
        textColor: AppCustomColor.textWhite,
      );
    }
    if (course.isNew) {
      return _BadgeChip(
        label: context.l10n.allcourse.newCourseLabel,
        backgroundColor: AppCustomColor.brandPrimary,
        textColor: AppCustomColor.textWhite,
      );
    }
    final completed = completedLessons ?? 0;
    final total = totalLessons ?? course.numberOfLesson;
    if (completed > 0 && total > 0) {
      final pct = (completed / total * 100).round();
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
        decoration: BoxDecoration(
          color: AppCustomColor.textPrimary.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(4.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12.w,
              height: 12.w,
              child: CircularProgressIndicator(
                value: completed / total,
                strokeWidth: 2,
                backgroundColor: Colors.white.withValues(alpha: 0.4),
                valueColor: const AlwaysStoppedAnimation(Colors.white),
              ),
            ),
            4.horizontalSpace,
            AppText(
              '$pct%',
              style: AppStyle.text10.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: AppText(
        label,
        style: AppStyle.text12.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
      ),
    );
  }
}
