part of '../../../course.dart';

class CourseRoadmapHeaderCard extends StatelessWidget {
  final RoadmapLevelEntity roadmapLevel;
  const CourseRoadmapHeaderCard({
    super.key,
    required this.roadmapLevel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Course title — tappable to navigate to ChangeCoursePage
          BlocSelector<HomeCubit, HomeState, String>(
            selector: (state) => state.courseName,
            builder: (context, courseName) {
              return Semantics(
                button: true,
                label: context.l10n.allcourse.changeCourseTitle,
                child: InkWell(
                  onTap: () => const ChangeCourseRoute().push(context),
                  borderRadius: BorderRadius.circular(4.r),
                  child: Column(
                    children: [
                      AppText(
                        courseName,
                        textWidthBasis: TextWidthBasis.longestLine,
                        style: AppStyle.text20.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppCustomColor.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.fade,
                      ),
                      8.verticalSpace,
                    ],
                  ),
                ),
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
