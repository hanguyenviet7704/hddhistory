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
      padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 32.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle Bar
          Center(
            child: Container(
              width: 48.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppCustomColor.borderDefault,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          32.verticalSpace,

          // Title
          AppText(
            lesson.title.text,
            style: AppStyle.textBold18,
            textAlign: TextAlign.start,
          ),
          16.verticalSpace,

          // Duration
          if (lesson.estimateCompleTime.en.isNotEmpty) ...[
            Row(
              children: [
                SvgPicture.asset(
                  AppAsset.svg.app.icClock,
                  width: 20.w,
                  height: 20.w,
                  colorFilter: ColorFilter.mode(
                    AppCustomColor.textSecondary,
                    BlendMode.srcIn,
                  ),
                ),
                8.horizontalSpace,
                AppText(
                  lesson.estimateCompleTime.text,
                  style: AppStyle.text14.copyWith(
                    color: AppCustomColor.textSecondary,
                  ),
                ),
              ],
            ),
            16.verticalSpace,
          ],

          // Description
          AppText(
            lesson.description.text,
            style: AppStyle.text14.copyWith(
              color: AppCustomColor.textSecondary,
              height: 1.5,
            ),
          ),
          32.verticalSpace,

          // Start Button
          AppButton.primary(
            child: 'Start Learning', // TODO: Add key to Sheets and regenerate
            onPressed: () => _onStartLearning(context),
            fullWidthBtn: true,
          ),
        ],
      ),
    );
  }
}
