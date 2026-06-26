part of '../../home.dart';

class CourseCardWidget extends StatelessWidget {
  final CourseEntity course;

  const CourseCardWidget({
    super.key,
    required this.course,
  });

  @override
  Widget build(BuildContext context) {
    final progress = _getCourseProgress(context);

    return GestureDetector(
      onTap: () {
        context.read<CourseRoadmapCubit>().setRoadmapSource('home_continue_learning');
        context.read<HomeCubit>()
          ..selectSkillset(course.skillset)
          ..selectCourse(course);
        CourseRoadmapRoute().go(context);
        context.read<PageCubit>().setCurrentIndex(1);
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
