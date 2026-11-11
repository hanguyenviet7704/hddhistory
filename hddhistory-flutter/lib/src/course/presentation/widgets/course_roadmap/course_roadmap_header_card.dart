part of '../../../course.dart';

/// Progress-bar track on the roadmap header (design #E3E8EF).
const Color _kRoadmapProgressTrack = Color(0xFFE3E8EF);

/// The meta line beside the bar — "23/60 · 48 min left" (design #9AA4B2), and
/// the dot between them (design #C5CBD6).
const Color _kRoadmapMetaText = Color(0xFF9AA4B2);
const Color _kRoadmapMetaDot = Color(0xFFC5CBD6);

/// Course blurb under "Inside this course" (design #7C8AA4).
const Color _kRoadmapBlurbText = Color(0xFF7C8AA4);

/// The course header at the top of the roadmap (design `3 · Learning` → Course
/// detail): artwork, title, how far in you are and how long is left, then what
/// the course actually contains.
///
/// It is drawn ONCE, above the first level — not per level as it used to be.
/// The level chip it carried is gone with it: the design has no level in the
/// roadmap, and the sections a reader actually navigates by are the nodes,
/// which already print their own title and blurb ([RoadmapNodeItem]).
class CourseRoadmapHeaderCard extends StatelessWidget {
  const CourseRoadmapHeaderCard({super.key, this.titleKey});

  /// Anchors the big title so the page can fade the sticky header title in as
  /// this one scrolls away (design: `setCourseTitleRef`).
  final GlobalKey? titleKey;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<HomeCubit, HomeState, CourseEntity>(
      selector: (state) => state.currentCourse,
      builder: (context, course) {
        return Padding(
          padding: EdgeInsets.fromLTRB(24.w, 6.h, 24.w, 12.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (course.image.isNotEmpty) ...[
                CacheNetworkGraphic(
                  url: course.image,
                  width: 132.w,
                  height: 132.w,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(26.r),
                ),
                16.verticalSpace,
              ],
              AppText(
                course.title.text,
                key: titleKey,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppFont.mulish,
                  fontSize: 23.sp,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                  color: studyThemeOnBg(context, AppCustomColor.textPrimary),
                ),
              ),
              10.verticalSpace,
              const _RoadmapProgressRow(),
              _RoadmapCourseBlurb(fallback: course.description),
            ],
          ),
        );
      },
    );
  }
}

/// "Inside this course" and the course blurb.
///
/// Reads the roadmap's copy of the description, not the course's: the payload
/// the catalogue lists come from deliberately drops `description`, so
/// `HomeCubit.currentCourse` carries an empty one. [fallback] is that course
/// value, used only if a build ever starts sending it there again.
class _RoadmapCourseBlurb extends StatelessWidget {
  const _RoadmapCourseBlurb({required this.fallback});

  final BaseMultiLanguage fallback;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CourseRoadmapCubit, CourseRoadmapState, BaseMultiLanguage>(
      selector: (state) => state.roadmap.courseDescription,
      builder: (context, description) {
        final text = description.text.trim().isNotEmpty ? description.text.trim() : fallback.text.trim();
        // An old server (or a course with no blurb) drops the whole block
        // rather than leaving a bare heading over nothing.
        if (text.isEmpty) return const SizedBox.shrink();

        return Column(
          children: [
            14.verticalSpace,
            AppText(
              context.l10n.courseroadmap.insideThisCourse,
              style: TextStyle(
                fontFamily: AppFont.mulish,
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: studyThemeAccentOnBg(context, AppCustomColor.brandPrimary),
              ),
            ),
            6.verticalSpace,
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 310.w),
              child: AppText(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFont.mulish,
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w500,
                  height: 1.55,
                  color: studyThemeOnBg(context, _kRoadmapBlurbText),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The 120-wide bar with the lesson count and the time left beside it.
///
/// Its own widget with its own selector: progress ticks on every completed
/// keypoint, and the artwork, title and blurb above have no reason to rebuild
/// for that.
class _RoadmapProgressRow extends StatelessWidget {
  const _RoadmapProgressRow();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CourseRoadmapCubit, CourseRoadmapState, RoadmapEntity>(
      selector: (state) => state.roadmap,
      builder: (context, roadmap) {
        if (roadmap.totalLessonCount == 0) return const SizedBox.shrink();

        final l10n = context.l10n.courseroadmap;
        final metaStyle = TextStyle(
          fontFamily: AppFont.mulish,
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
          letterSpacing: 11 * 0.04,
          color: studyThemeOnBg(context, _kRoadmapMetaText),
        );

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Kept animated (and kept on percent_indicator) so the bar grows
            // into its new value when a lesson completes rather than jumping —
            // the reader often lands back here straight from finishing one.
            LinearPercentIndicator(
              animation: true,
              animationDuration: 500,
              animateFromLastPercent: true,
              width: 120.w,
              lineHeight: 8.h,
              percent: roadmap.courseProgress,
              backgroundColor: _kRoadmapProgressTrack,
              progressColor: AppCustomColor.brandPrimary,
              barRadius: Radius.circular(99.r),
              padding: EdgeInsets.zero,
            ),
            10.horizontalSpace,
            AppText(
              l10n.progressCount(
                completed: roadmap.completedLessonCount,
                total: roadmap.totalLessonCount,
              ),
              style: metaStyle,
            ),
            if (roadmap.hasMinutesLeft) ...[
              10.horizontalSpace,
              Container(
                width: 3.w,
                height: 3.w,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: _kRoadmapMetaDot),
              ),
              10.horizontalSpace,
              AppText(l10n.minutesLeft(minutes: roadmap.minutesLeft), style: metaStyle),
            ],
          ],
        );
      },
    );
  }
}
