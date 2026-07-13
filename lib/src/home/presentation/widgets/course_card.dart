part of '../../home.dart';

/// Large portrait course card (335×380) for the Home "Continue learning" PageView.
///
/// Matches the Figma design: mint background, circular course image centred in
/// the top half, skillset label + course title in the bottom section, and an
/// absolute-positioned progress badge in the top-right corner.
class HomeLargePortraitCourseCard extends StatelessWidget {
  final CourseEntity course;
  final double? progressPercentage;

  const HomeLargePortraitCourseCard({
    super.key,
    required this.course,
    this.progressPercentage,
  });

  @override
  Widget build(BuildContext context) {
    final progress = progressPercentage ?? 0.0;

    return Semantics(
      button: true,
      label: course.title.text,
      child: GestureDetector(
        onTap: () {
          context.read<CourseRoadmapCubit>().setRoadmapSource('home_continue_learning');
          context.read<HomeCubit>()
            ..selectSkillset(course.skillset)
            ..selectCourse(course);
          CourseRoadmapRoute().go(context);
          // Not just setCurrentIndex(1): .go() to the roadmap branch root
          // doesn't re-fire the route observer, so currentRouteName would
          // stay on 'home' — silently skipping the re-anchor prompt (§9.1)
          // for the app's most common course-entry point (mirrors the fix in
          // all_course_tab.dart's _handleCourseTap).
          context.read<PageCubit>().setCurrentRouteName(RouteNamed.courseRoadmap);
        },
        child: Container(
          width: 335.w,
          height: 380.h,
          decoration: BoxDecoration(
            // Figma: light mint background
            color: const Color(0xFFECF2F3),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Stack(
            children: [
              // ── Main content ───────────────────────────────────────────
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Course image — centred in the top half
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 200.w,
                        height: 200.w,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22.r),
                          border: Border.all(color: AppCustomColor.backgroundWhite, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEBF0F7).withValues(alpha: 0.26),
                              blurRadius: 30,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20.r),
                          child: CacheNetworkGraphic(
                            url: course.image,
                            width: 200.w,
                            height: 200.w,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Skillset label + course title
                  Padding(
                    padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 24.h),
                    child: Column(
                      children: [
                        AppText(
                          course.skillset.title.text.toUpperCase(),
                          style: AppStyle.textBold12.copyWith(
                            color: AppCustomColor.textPrimary.withValues(alpha: 0.50),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        4.verticalSpace,
                        AppText(
                          course.title.text,
                          style: AppStyle.textBold20.copyWith(color: AppCustomColor.textPrimary),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // ── Progress badge — absolute top-right corner ─────────────
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppCustomColor.backgroundWhite,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(8.r),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 14.w,
                        height: 14.w,
                        child: CircularProgressIndicator(
                          value: progress / 100,
                          strokeWidth: 2,
                          backgroundColor: AppCustomColor.borderDefault,
                          color: AppCustomColor.brandPrimary,
                        ),
                      ),
                      4.horizontalSpace,
                      AppText(
                        context.l10n.allcourse.progressPercent(
                          percent: progress.toInt(),
                        ),
                        style: AppStyle.textBold12.copyWith(
                          color: AppCustomColor.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact horizontal course card used in "Recommended courses" and similar
/// horizontal scroll lists.
class CourseCardWidget extends StatelessWidget {
  final CourseEntity course;

  const CourseCardWidget({
    super.key,
    required this.course,
  });

  @override
  Widget build(BuildContext context) {
    final progress = _getCourseProgress(context);

    return Semantics(
      button: true,
      label: course.title.text,
      child: GestureDetector(
        onTap: () {
          context.read<CourseRoadmapCubit>().setRoadmapSource('home_continue_learning');
          context.read<HomeCubit>()
            ..selectSkillset(course.skillset)
            ..selectCourse(course);
          CourseRoadmapRoute().go(context);
          // Not just setCurrentIndex(1): .go() to the roadmap branch root
          // doesn't re-fire the route observer, so currentRouteName would
          // stay on 'home' — silently skipping the re-anchor prompt (§9.1)
          // for the app's most common course-entry point (mirrors the fix in
          // all_course_tab.dart's _handleCourseTap).
          context.read<PageCubit>().setCurrentRouteName(RouteNamed.courseRoadmap);
        },
        child: Container(
        width: 220.w,
        margin: EdgeInsets.only(right: 16.w),
        decoration: BoxDecoration(
          color: AppCustomColor.backgroundWhite,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppCustomColor.borderDefault),
          boxShadow: [
            BoxShadow(
              color: AppCustomColor.textPrimary.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail with badge overlay
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
                  child: CacheNetworkGraphic(
                    url: course.image,
                    width: double.infinity,
                    height: 130.h,
                    fit: BoxFit.cover,
                  ),
                ),
                // Progress badge — top-right corner
                if (progress > 0)
                  Positioned(
                    top: 10.h,
                    right: 10.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: AppCustomColor.backgroundWhite.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 14.w,
                            height: 14.w,
                            child: CircularProgressIndicator(
                              value: progress / 100,
                              strokeWidth: 2,
                              backgroundColor: AppCustomColor.borderDefault,
                              color: AppCustomColor.brandPrimary,
                            ),
                          ),
                          4.horizontalSpace,
                          AppText(
                            '${progress.toInt()}%',
                            style: AppStyle.text10.copyWith(
                              color: AppCustomColor.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Positioned(
                    top: 10.h,
                    right: 10.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: AppCustomColor.brandPrimary,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: AppText(
                        'New',
                        style: AppStyle.text10.copyWith(
                          color: AppCustomColor.backgroundWhite,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // Card body
            Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    course.skillset.title.text.toUpperCase(),
                    style: AppStyle.text10.copyWith(
                      color: AppCustomColor.brandPrimary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                  ),
                  6.verticalSpace,
                  AppText(
                    course.title.text,
                    maxLines: 2,
                    style: AppStyle.textBold14.copyWith(
                      color: AppCustomColor.textPrimary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  /// Returns the completion percentage (0–100) for this course.
  ///
  /// The current data model does not expose a pre-computed progress
  /// percentage per course in the home context, so this always returns 0,
  /// which causes the "New" badge to be shown. When the backend adds a
  /// per-course progress field, update this method accordingly.
  double _getCourseProgress(BuildContext context) {
    return 0;
  }
}
