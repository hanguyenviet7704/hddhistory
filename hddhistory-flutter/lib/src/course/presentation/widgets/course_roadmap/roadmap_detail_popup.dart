part of '../../../course.dart';

const _roadmapDetailSheetSurfaceKey = ValueKey('roadmap-detail-sheet-surface');

class RoadmapDetailPopup extends StatelessWidget {
  const RoadmapDetailPopup({
    super.key,
    required this.lesson,
    required this.courseLevel,
    this.bottomInset = 0,
    this.onStart,
  });

  final LessonEntity lesson;
  final CourseLevel courseLevel;
  final double bottomInset;
  final VoidCallback? onStart;

  KeypointEntity get keypoint => lesson.firstKeypoint;

  bool get hasAudio => keypoint.hasUsableAudio;

  static Future<void> show(
    BuildContext context, {
    required LessonEntity lesson,
    required CourseLevel courseLevel,
  }) async {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    // popup_item_imp tracking removed per request.

    final keypointTracking = KeypointTrackingData.fromLesson(
      context,
      lesson: lesson,
      keypoint: lesson.firstKeypoint,
    );
    if (lesson.firstKeypoint.hasUsableAudio && keypointTracking != null) {
      AppService.instance.appTrackingService.trackKeypointAudioPopupView(keypointTracking);
    }

    var didStart = false;
    await showModalBottomSheet<void>(
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
          bottomInset: bottomInset,
          onStart: () => didStart = true,
        ),
      ),
    );

    if (!didStart && lesson.firstKeypoint.hasUsableAudio && keypointTracking != null) {
      AppService.instance.appTrackingService.trackKeypointAudioPopupExitClick(keypointTracking);
    }
  }

  Future<void> _startLearning(BuildContext context) async {
    if (lesson.id.isEmpty || keypoint.id.isEmpty) return;
    onStart?.call();

    // final trackingData = CourseLessonTrackingData.fromLesson(context, lesson);
    // if (trackingData != null) {
    //   AppService.instance.appTrackingService.trackPopupItemClick(trackingData);
    // }
    //
    // The old Đọc/Nghe (Read/Listen) two-button picker collapsed into this
    // single Start CTA now that the keypoint screen is unified — there is no
    // mode choice left to track here. `trackKeypointAudioPopupReadClick` /
    // `trackKeypointAudioPopupListenClick` are no longer called from
    // anywhere; left defined on the tracking service for the dashboard owner
    // to formally retire.

    // Capture everything needed before closing the sheet below — `context`
    // (this popup's own) is disposed the instant it pops.
    final lessonCubit = context.read<LessonCubit>();
    final courseLessonCubit = context.read<CourseLessonCubit>();
    final roadmapCubit = context.read<CourseRoadmapCubit>();

    context.back();

    // The re-anchor prompt ("Why does this matter to you?") used to open here,
    // between committing to a lesson and starting it. Dropped in this release:
    // starting a lesson goes straight to the lesson.
    final rootContext = AppConfig.instance.context;
    if (rootContext == null || !rootContext.mounted) return;

    startKeypointLesson(
      lessonCubit: lessonCubit,
      courseLessonCubit: courseLessonCubit,
      roadmapCubit: roadmapCubit,
      navContext: rootContext,
      lesson: lesson,
      keypoint: keypoint,
      courseLevel: courseLevel,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolvedBottomInset = bottomInset > 0 ? bottomInset : MediaQuery.viewPaddingOf(context).bottom;

    return Column(
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
          key: _roadmapDetailSheetSurfaceKey,
          decoration: BoxDecoration(
            color: AppCustomColor.backgroundWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
          ),
          padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, resolvedBottomInset + 16.h),
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
              // A single Start CTA — the unified keypoint screen has no
              // separate Read/Listen entry anymore (default assumption for
              // this merge; easy to revisit if a future need calls for two
              // distinct entry buttons again). Narration autoplays on its own
              // once inside whenever `hasAudio` is true, so there's nothing
              // left for a second button to pick between.
              _RoadmapDetailActionButton(
                key: const ValueKey('roadmap-detail-start-button'),
                label: context.l10n.lesson.startLearningLabel,
                // One icon for every keypoint, audio or not: the button starts
                // the same screen either way, so a music note on some cards and
                // a list on others read as two different actions.
                iconAsset: AppAsset.svg.app.icMenu,
                backgroundColor: const Color(0xFFB5860F),
                foregroundColor: Colors.white,
                onTap: () => unawaited(_startLearning(context)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoadmapDetailActionButton extends StatelessWidget {
  const _RoadmapDetailActionButton({
    super.key,
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
      onTap: () {
        AppHaptic.select();
        onTap();
      },
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
