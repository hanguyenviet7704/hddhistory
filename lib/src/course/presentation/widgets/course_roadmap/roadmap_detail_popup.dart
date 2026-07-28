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
    final roadmapState = roadmapCubit.state;

    // Close the Read/Listen picker immediately — Re-anchor (if it fires below)
    // is a full-screen "before you start" gate, not a page stacked on top of
    // this sheet.
    context.back();

    // Re-anchor (§9.1): asked right here — the moment the user has committed
    // to a specific lesson AND mode — not at course/roadmap entry (too early:
    // they haven't decided to study yet, may just be browsing). The sync
    // guards below resolve instantly for the common case (course already in
    // progress), so most lesson starts see no added delay; the reasons fetch
    // itself is usually already warm (see CourseRoadmapCubit.loadRoadmap).
    ReanchorReasonEntity? pickedReason;
    final reasons = await _resolveReanchorReasons(roadmapState);
    if (reasons != null) {
      final rootContext = AppConfig.instance.context;
      if (rootContext != null && rootContext.mounted) {
        pickedReason = await ReanchorPage.push(rootContext, reasons: reasons);
      }
    }

    final rootContext = AppConfig.instance.context;
    if (rootContext == null || !rootContext.mounted) return;

    lessonCubit
      ..reset()
      ..loadAllLearningItems(keypointId: keypoint.id, isInit: true);
    courseLessonCubit
      ..setSelectedLesson(lesson)
      ..setCurrentKeypointId(keypoint.id)
      ..loadLesson(lesson.id);

    // `initial-mode` is repurposed to "autoplay narration for the first
    // keypoint on entry" (see `LessonRoute`/`LessonPage`) — this Start CTA is
    // the primary real-world path into a keypoint, so it opts in whenever
    // there's usable audio to autoplay.
    LessonRoute(initialMode: hasAudio ? LessonEntryMode.audio.routeValue : LessonEntryMode.read.routeValue).go(rootContext);

    roadmapCubit
      ..setCurrentCourseLevel(courseLevel)
      ..setCurrentLesson(lesson);

    // Remember the picked reason so it can be attached when a habit is later
    // adopted from this course (§9.5 tracker cluster title).
    if (pickedReason != null) {
      AppDI.injector.get<HabitCubit>().setReanchorReason(roadmapState.roadmap.courseId, pickedReason);
    }
  }

  /// Resolves the Re-anchor reasons to show, or null if the prompt shouldn't
  /// appear for this lesson start: already shown for this course, the course
  /// has a completed lesson (Lesson 2+ skips it — PRD §9.1), or nothing is
  /// BTV-configured. Marks the course as shown the instant it decides to
  /// return reasons, so a second concurrent call (shouldn't normally happen —
  /// there's only one picker open at a time — but cheap to guard) can't also
  /// return non-null and double-show the prompt.
  Future<List<ReanchorReasonEntity>?> _resolveReanchorReasons(CourseRoadmapState roadmapState) async {
    // NOT lesson.courseId — roadmap-sourced lessons never carry it (only the
    // top-level RoadmapEntity does), so it's reliably empty here.
    final courseId = roadmapState.roadmap.courseId;
    if (courseId.isEmpty || roadmapState.roadmap.levels.isEmpty) return null;
    final habitCubit = AppDI.injector.get<HabitCubit>();
    if (habitCubit.state.reanchorShownCourseIds.contains(courseId)) return null;
    final completedLessons = roadmapState.roadmap.levels.fold<int>(0, (sum, level) => sum + level.completedLessons);
    if (completedLessons > 0) return null;

    final reasons = await habitCubit.getReanchorReasons(courseId);
    if (reasons.isEmpty) return null;
    if (habitCubit.state.reanchorShownCourseIds.contains(courseId)) return null;
    habitCubit.markReanchorShown(courseId);
    return reasons;
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
                iconAsset: hasAudio ? AppAsset.svg.app.icMusicNote : AppAsset.svg.app.icMenu,
                backgroundColor: const Color(0xFF554FF0),
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
