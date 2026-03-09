part of '../../../course.dart';

class RoadmapDetailPopup extends StatelessWidget {
  final LessonEntity lesson;
  final CourseLevel courseLevel;

  const RoadmapDetailPopup({
    super.key,
    required this.lesson,
    required this.courseLevel,
  });

  KeypointEntity get keypoint => lesson.firstKeypoint;

  static Future<void> show(
    BuildContext context, {
    required LessonEntity lesson,
    required CourseLevel courseLevel,
  }) async {
    final trackingData = CourseLessonTrackingData.fromLesson(context, lesson);
    if (trackingData != null) {
      AppService.instance.appTrackingService.trackPopupItemImp(trackingData);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppCustomColor.scrimOverlay,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.sp))),
      routeSettings: const RouteSettings(name: RouteNamed.roadmapDetailPopup),
      useRootNavigator: true,
      builder: (context) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: AppDI.injector.get<CourseRoadmapCubit>()),
          BlocProvider.value(value: AppDI.injector.get<CourseLessonCubit>()),
          BlocProvider.value(value: AppDI.injector.get<HomeCubit>()),
          BlocProvider.value(value: AppDI.injector.get<LessonCubit>()),
        ],
        child: RoadmapDetailPopup(
          lesson: lesson,
          courseLevel: courseLevel,
        ),
      ),
    );
  }

  void _onStartLearning(BuildContext context) {
    if (lesson.id.isEmpty) return;

    final trackingData = CourseLessonTrackingData.fromLesson(context, lesson);
    if (trackingData != null) {
      AppService.instance.appTrackingService.trackPopupItemClick(trackingData);
    }

    // if (roleplay.id.isNotEmpty) {
    //   context.read<ProgressCubit>().loadUserProgressLesson(lessonId: roleplay.id);
    // }

    if (keypoint.id.isEmpty) return;

    // Navigation Logic
    context.read<LessonCubit>()
      ..reset()
      ..loadAllLearningItems(keypointId: keypoint.id, isInit: true);
    context.read<CourseLessonCubit>()
      ..setSelectedLesson(lesson)
      ..setCurrentKeypointId(keypoint.id)
      ..loadLesson(lesson.id);
    LessonRoute().go(context);

    context.read<CourseRoadmapCubit>()
      ..setCurrentCourseLevel(courseLevel)
      ..setCurrentLesson(lesson);

    context.back();
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
            keypoint.title.text,
            style: AppStyle.textBold24,
            maxLines: 3,
            textAlign: TextAlign.center,
          ),
          8.verticalSpace,

          // Duration
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppText(
                context.text.courseroadmap.keypointLabel.toUpperCase(),
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
                keypoint.estimateCompleTime.text.toUpperCase(),
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

          // Description
          AppText(
            keypoint.description.text,
            textAlign: TextAlign.center,
            maxLines: 10,
            style: AppStyle.text14.copyWith(
              color: AppCustomColor.textSecondary,
              height: 1.75,
            ),
          ),
          40.verticalSpace,

          // Start Button
          AppButton.primary(
            onPressed: () => _onStartLearning(context),
            fullWidthBtn: true,
            height: 54.h,
            borderRadius: BorderRadius.circular(1000.r),
            child: AppText(
              context.text.courseroadmap.startLearningButton,
              style: AppStyle.textBold16.copyWith(
                color: AppCustomColor.textWhite,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
