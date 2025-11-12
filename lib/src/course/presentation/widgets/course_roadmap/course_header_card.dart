part of '../../../course.dart';

class CourseHeaderCard extends StatelessWidget {
  const CourseHeaderCard({super.key});

  String _getLevelText(CourseEntity course) {
    return 'Course';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundWhite,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppCustomColor.borderDefault,
            blurRadius: 4,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, homeState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Course title
              AppText(
                homeState.courseName,
                style: AppStyle.text24.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppCustomColor.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              8.verticalSpace,
              // Course description
              if (homeState.currentCourse.description.text.isNotEmpty) ...[
                AppText(
                  margin: EdgeInsets.symmetric(horizontal: 16.w),
                  homeState.currentCourse.description.text,
                  style: AppStyle.text14.copyWith(
                    color: AppCustomColor.textSecondary,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                12.verticalSpace,
              ],

              // Progress bar
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                child: Row(
                  children: [
                    AppText(
                      _getLevelText(homeState.currentCourse).toUpperCase(),
                      style: AppStyle.textBold12.copyWith(color: AppCustomColor.textTertiary),
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
                    BlocSelector<CourseRoadmapCubit, CourseRoadmapState, double>(
                      selector: (state) => state.progress,
                      builder: (context, progress) {
                        return Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4.r),
                            child: LinearPercentIndicator(
                              animation: true,
                              animationDuration: 500,
                              animateFromLastPercent: true,
                              lineHeight: 10.h,
                              percent: progress,
                              backgroundColor: const Color(0xFFE3E8EF), // Neutral/200
                              progressColor: const Color(0xFF0D121C), // Brand/Brand/Primary/300
                              barRadius: Radius.circular(30.r),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        );
                      },
                    ),
                    12.horizontalSpace,
                    // Lesson count
                    BlocBuilder<CourseRoadmapCubit, CourseRoadmapState>(
                      buildWhen: (previous, current) => previous.completedLessons != current.completedLessons || previous.totalLessons != current.totalLessons,
                      builder: (context, courseState) {
                        return AppText(
                          '${courseState.completedLessons}/${courseState.totalLessons} Lessons',
                          style: AppStyle.text14.copyWith(
                            color: AppCustomColor.textTertiary,
                          ),
                          maxLines: 1,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
