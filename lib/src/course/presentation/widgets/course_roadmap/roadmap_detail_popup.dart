part of '../../../course.dart';

class RoadmapDetailPopup extends StatelessWidget {
  final LessonEntity lesson;
  final CourseLevel courseLevel;

  const RoadmapDetailPopup({
    super.key,
    required this.lesson,
    required this.courseLevel,
  });

  static Future<void> show(
    BuildContext context, {
    required LessonEntity lesson,
    required CourseLevel courseLevel,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppCustomColor.scrimOverlay,
      builder: (context) => RoadmapDetailPopup(
        lesson: lesson,
        courseLevel: courseLevel,
      ),
    );
  }

  void _onStartLearning(BuildContext context) {
    if (lesson.id.isEmpty) return;

    // Tracking
    final trackingData = CourseLessonTrackingData.fromLesson(context, lesson);
    if (trackingData != null) {
      AppService.instance.appTrackingService.trackRoadmapItemClick(
        trackingData,
        itemType: 'lesson_popup_start',
      );
    }

    // Navigation Logic
    context.read<CourseLessonCubit>()
      ..reset()
      ..loadLesson(lesson.id);

    LessonListRoute().go(context);

    context.read<CourseRoadmapCubit>()
      ..setCurrentCourseLevel(courseLevel)
      ..setCurrentLesson(lesson);

    Navigator.of(context).pop(); // Close popup
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle Bar
          Center(
            child: Container(
              width: 50.w,
              height: 5.h,
              decoration: BoxDecoration(
                color: AppCustomColor.backgroundWhite,
                borderRadius: BorderRadius.circular(30.r),
              ),
            ),
          ),
          24.verticalSpace,

          // Title
          AppText(
            lesson.title.text,
            style: AppStyle.textBold24,
            textAlign: TextAlign.center,
          ),
          8.verticalSpace,

          // Duration
          if (lesson.estimateCompleTime.en.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppText(
                  'KEYPOINT',
                  style: AppStyle.text12.copyWith(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: AppCustomColor.textTertiary,
                    height: 1.75,
                  ),
                ),
                12.horizontalSpace,
                Container(
                  width: 4.w,
                  height: 4.w,
                  decoration: const ShapeDecoration(
                    color: AppCustomColor.textTertiary,
                    shape: OvalBorder(),
                  ),
                ),
                12.horizontalSpace,
                SvgPicture.asset(
                  AppAsset.svg.app.icClock,
                  width: 16.w,
                  height: 16.w,
                  colorFilter: ColorFilter.mode(
                    AppCustomColor.textTertiary,
                    BlendMode.srcIn,
                  ),
                ),
                8.horizontalSpace,
                AppText(
                  lesson.estimateCompleTime.text.toUpperCase(),
                  style: AppStyle.text12.copyWith(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: AppCustomColor.textTertiary,
                    height: 1.75,
                  ),
                ),
              ],
            ),
            12.verticalSpace,
          ],

          // Description
          AppText(
            lesson.description.text,
            style: AppStyle.text14.copyWith(
              color: AppCustomColor.textSecondary,
              height: 1.75,
            ),
          ),
          40.verticalSpace,

          // Start Button
          AppButton.primary(
            child: AppText(
              'Start learning',
              style: AppStyle.textBold16.copyWith(
                color: AppCustomColor.textWhite,
              ),
              textAlign: TextAlign.center,
            ), // TODO: Add key to Sheets and regenerate
            onPressed: () => _onStartLearning(context),
            fullWidthBtn: true,
            height: 54.h,
            borderRadius: BorderRadius.circular(1000.r),
          ),
        ],
      ),
    );
  }
}
