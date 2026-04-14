part of '../../../course.dart';

class RoadmapDetailPopup extends StatelessWidget {
  const RoadmapDetailPopup({
    super.key,
    required this.lesson,
    required this.courseLevel,
  });

  final LessonEntity lesson;
  final CourseLevel courseLevel;

  KeypointEntity get keypoint => lesson.firstKeypoint;

  bool get hasAudio => keypoint.hasUsableAudio;

  static Future<void> show(
    BuildContext context, {
    required LessonEntity lesson,
    required CourseLevel courseLevel,
  }) async {
    final trackingData = CourseLessonTrackingData.fromLesson(context, lesson);
    if (trackingData != null) {
      AppService.instance.appTrackingService.trackPopupItemImp(trackingData);
    }

    final keypointTracking = KeypointTrackingData.fromLesson(
      context,
      lesson: lesson,
      keypoint: lesson.firstKeypoint,
    );
    if (lesson.firstKeypoint.hasUsableAudio && keypointTracking != null) {
      AppService.instance.appTrackingService.trackKeypointAudioPopupView(keypointTracking);
    }

    return showModalBottomSheet<void>(
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

  void _startLearning(BuildContext context, LessonEntryMode mode) {
    if (lesson.id.isEmpty || keypoint.id.isEmpty) return;

    final trackingData = CourseLessonTrackingData.fromLesson(context, lesson);
    if (trackingData != null) {
      AppService.instance.appTrackingService.trackPopupItemClick(trackingData);
    }

    final keypointTracking = KeypointTrackingData.fromLesson(
      context,
      lesson: lesson,
      keypoint: keypoint,
    );
    if (hasAudio && keypointTracking != null) {
      if (mode.isAudio) {
        AppService.instance.appTrackingService.trackKeypointAudioPopupListenClick(keypointTracking);
      } else {
        AppService.instance.appTrackingService.trackKeypointAudioPopupReadClick(keypointTracking);
      }
    }

    context.read<LessonCubit>()
      ..reset()
      ..loadAllLearningItems(keypointId: keypoint.id, isInit: true);
    context.read<CourseLessonCubit>()
      ..setSelectedLesson(lesson)
      ..setCurrentKeypointId(keypoint.id)
      ..loadLesson(lesson.id);

    LessonRoute(initialMode: mode.routeValue).go(context);

    context.read<CourseRoadmapCubit>()
      ..setCurrentCourseLevel(courseLevel)
      ..setCurrentLesson(lesson);

    context.back();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewPaddingOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50.w,
            height: 5.h,
            decoration: BoxDecoration(
              color: AppCustomColor.backgroundWhite,
              borderRadius: BorderRadius.circular(30.r),
            ),
          ),
          SizedBox(height: 6.h),
          Container(
            decoration: BoxDecoration(
              color: AppCustomColor.backgroundWhite,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
            ),
            padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 16.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppText(
                  keypoint.title.text,
                  style: AppStyle.textBold24.copyWith(
                    color: AppCustomColor.textPrimary,
                  ),
                  maxLines: 3,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppText(
                      context.l10n.courseroadmap.keypointLabel.toUpperCase(),
                      style: AppStyle.text12.copyWith(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: AppCustomColor.textTertiary,
                        height: 1.75,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Container(
                      width: 4.w,
                      height: 4.w,
                      decoration: const ShapeDecoration(
                        color: AppCustomColor.textTertiary,
                        shape: OvalBorder(),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    SvgPicture.asset(
                      AppAsset.svg.app.icClock,
                      width: 16.w,
                      height: 16.w,
                      colorFilter: ColorFilter.mode(
                        AppCustomColor.textTertiary,
                        BlendMode.srcIn,
                      ),
                    ),
                    SizedBox(width: 8.w),
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
                SizedBox(height: 12.h),
                AppText(
                  keypoint.description.text,
                  textAlign: TextAlign.center,
                  style: AppStyle.text14.copyWith(
                    color: AppCustomColor.textSecondary,
                    height: 1.75,
                  ),
                ),
                SizedBox(height: 40.h),
                if (hasAudio)
                  Row(
                    children: [
                      Expanded(
                        child: _RoadmapDetailActionButton(
                          label: context.l10n.lesson.audioReadLabel,
                          iconAsset: AppAsset.svg.app.icMenu,
                          backgroundColor: AppCustomColor.brandPrimary50,
                          foregroundColor: const Color(0xFF4B44CA),
                          onTap: () => _startLearning(context, LessonEntryMode.read),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: _RoadmapDetailActionButton(
                          label: context.l10n.lesson.audioListenLabel,
                          iconAsset: AppAsset.svg.app.icMusicNote,
                          backgroundColor: const Color(0xFF554FF0),
                          foregroundColor: Colors.white,
                          onTap: () => _startLearning(context, LessonEntryMode.audio),
                        ),
                      ),
                    ],
                  )
                else
                  _RoadmapDetailActionButton(
                    label: context.l10n.lesson.audioReadLabel,
                    iconAsset: AppAsset.svg.app.icMenu,
                    backgroundColor: AppCustomColor.brandPrimary50,
                    foregroundColor: const Color(0xFF4B44CA),
                    onTap: () => _startLearning(context, LessonEntryMode.read),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoadmapDetailActionButton extends StatelessWidget {
  const _RoadmapDetailActionButton({
    required this.label,
    required this.iconAsset,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
  });

  final String label;
  final String iconAsset;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 54.h,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(1000.r),
        ),
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              iconAsset,
              width: 20.w,
              height: 20.w,
              colorFilter: ColorFilter.mode(
                foregroundColor,
                BlendMode.srcIn,
              ),
            ),
            SizedBox(width: 10.w),
            Flexible(
              child: AppText(
                label,
                style: AppStyle.textBold16.copyWith(
                  color: foregroundColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
