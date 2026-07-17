part of '../../../course.dart';

class CourseListTile extends StatelessWidget {
  const CourseListTile({
    super.key,
    required this.course,
    this.isSelected = false,
    this.showBorder = true,
    this.onTap,
  });

  final CourseEntity course;
  final bool isSelected;

  /// When false, no card border or background is drawn.
  /// Use this in search results where a Divider separator replaces card borders.
  final bool showBorder;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: course.title.text,
      button: onTap != null,
      selected: isSelected,
      child: GestureDetector(
        onTap: onTap == null
            ? null
            : () {
                AppHaptic.select();
                onTap!();
              },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: showBorder
              ? BoxDecoration(
                  color: isSelected
                      ? AppCustomColor.brandPrimary50
                      : AppCustomColor.backgroundWhite,
                  border: Border.all(
                    color: isSelected
                        ? AppCustomColor.brandPrimary
                        : AppCustomColor.borderDefault,
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                )
              : null,
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

  Widget _chip({required Widget icon, required String label, required Color color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: 14.w, height: 14.w, child: Center(child: icon)),
        4.horizontalSpace,
        Flexible(
          child: AppText(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppStyle.text12.copyWith(color: color),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Coming soon courses always show the coming-soon label, regardless of progress
    // (Figma course-card state set, node 10840-20051 — clock + brand text).
    if (course.status == CoursePublishStatus.comingSoon) {
      return _chip(
        icon: Icon(Icons.access_time_filled_rounded, size: 14.w, color: AppCustomColor.brandPrimary700),
        label: context.l10n.allcourse.comingSoonLabel,
        color: AppCustomColor.brandPrimary700,
      );
    }

    final progressState = context.watch<ProgressCubit>().state;
    final userProgress = progressState.userProgresses
        .firstWhereOrNull((p) => p.courseId == course.id);

    final completed = userProgress?.lessonsResult.where((r) => r.passed).length ?? 0;
    final total = course.numberOfLesson;

    // New course with zero progress — sparkle + brand/secondary/700 green
    // (Figma node 10736-50550, Card3X1 "new" state).
    if (course.isNew && completed == 0) {
      return _chip(
        icon: Icon(Icons.auto_awesome_rounded, size: 14.w, color: _kBadgeGreen),
        label: context.l10n.allcourse.newCourseLabel,
        color: _kBadgeGreen,
      );
    }

    if (userProgress == null || userProgress.lessonsResult.isEmpty) {
      // Not started — lesson count + solid book icon, matching the Explore grid
      // badge and Figma's "not started" variant (which shows "N lessons", not
      // literal "Not started" text).
      if (total > 0) {
        return _chip(
          icon: SvgPicture.asset(AppAsset.svg.app.icBookSolid, width: 14.w, height: 14.w),
          label: context.l10n.allcourse.lessonsCount(count: total),
          color: AppCustomColor.streakTextMuted,
        );
      }
      return AppText(
        context.l10n.allcourse.progressNotStarted,
        style: AppStyle.text12.copyWith(color: AppCustomColor.streakTextMuted),
      );
    }

    if (total > 0 && completed >= total) {
      return _chip(
        icon: Icon(Icons.check_circle_rounded, size: 14.w, color: _kBadgeGreen),
        label: context.l10n.allcourse.progressCompleted,
        color: _kBadgeGreen,
      );
    }

    final percent = (total > 0) ? (completed / total * 100).toInt() : 0;
    if (percent > 0) {
      return _chip(
        icon: SizedBox(
          width: 14.w,
          height: 14.w,
          child: CircularProgressIndicator(
            value: total > 0 ? completed / total : 0,
            strokeWidth: 2.w,
            backgroundColor: AppCustomColor.borderDefault,
            color: AppCustomColor.brandPrimary,
          ),
        ),
        label: context.l10n.allcourse.progressPercent(percent: percent),
        color: AppCustomColor.brandPrimary,
      );
    }

    // Completed at least one lesson but less than tracked minimum — show "Not started".
    return AppText(
      context.l10n.allcourse.progressNotStarted,
      style: AppStyle.text12.copyWith(color: AppCustomColor.streakTextMuted),
    );
  }
}
