part of '../../../course.dart';

class CourseRoadmapHeaderCard extends StatelessWidget {
  final RoadmapLevelEntity roadmapLevel;
  const CourseRoadmapHeaderCard({
    super.key,
    required this.roadmapLevel,
  });

  @override
  Widget build(BuildContext context) {
    // The course thumbnail belongs to the course as a whole, so it is shown
    // once — above the first level's header — matching the Figma roadmap.
    final isFirstLevel = context.select<CourseRoadmapCubit, bool>((cubit) {
      final levels = cubit.state.roadmap.levels;
      return levels.isNotEmpty && levels.first.level == roadmapLevel.level;
    });
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (isFirstLevel) ...[
            BlocSelector<HomeCubit, HomeState, String>(
              selector: (state) => state.currentCourse.image,
              builder: (context, image) {
                if (image.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: EdgeInsets.only(bottom: 24.h),
                  child: Container(
                    width: 120.w,
                    height: 120.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppCustomColor.borderDefault,
                          blurRadius: 28.r,
                        ),
                      ],
                    ),
                    child: CacheNetworkGraphic(
                      url: image,
                      width: 120.w,
                      height: 120.w,
                      fit: BoxFit.cover,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                  ),
                );
              },
            ),
          ],
          // Course title (display only — tapping no longer opens the
          // "Change course" page).
          BlocSelector<HomeCubit, HomeState, String>(
            selector: (state) => state.courseName,
            builder: (context, courseName) {
              return Column(
                children: [
                  AppText(
                    courseName,
                    textWidthBasis: TextWidthBasis.longestLine,
                    // Heading/H3/Bold — Mulish Bold 20 / 1.5 (Figma 10735:49368).
                    style: AppStyle.text20.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppCustomColor.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.fade,
                  ),
                  // Title → level/progress: Figma title-block gap (12) + the
                  // progress row's own top padding (8) = 20.
                  20.verticalSpace,
                ],
              );
            },
          ),

          // Progress bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            child: Row(
              children: [
                AppText(
                  roadmapLevel.level.name.toUpperCase(),
                  style: AppStyle.textBold10.copyWith(color: AppCustomColor.textTertiary),
                  maxLines: 1,
                ),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 12.w),
                  width: 4.w,
                  height: 4.w,
                  decoration: ShapeDecoration(
                    color: const Color(0xFFAAB7CC) /* Text-Quaternary */,
                    shape: OvalBorder(),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4.r),
                    child: LinearPercentIndicator(
                      animation: true,
                      animationDuration: 500,
                      animateFromLastPercent: true,
                      lineHeight: 9.h,
                      percent: roadmapLevel.progress,
                      backgroundColor: const Color(0xFFE3E8EF), // Neutral/200
                      progressColor: const Color(0xFF4B44CA), // Brand/Primary
                      barRadius: Radius.circular(18.r),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
                12.horizontalSpace,
                // Lesson count
                AppText(
                  context.l10n.courseroadmap
                      .lessonsProgress(
                        completed: roadmapLevel.completedLessons,
                        total: roadmapLevel.totalLessons,
                      )
                      .toUpperCase(),
                  style: AppStyle.textBold10.copyWith(
                    color: AppCustomColor.textTertiary,
                  ),
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
