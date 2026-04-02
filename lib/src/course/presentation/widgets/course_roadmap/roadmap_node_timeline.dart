part of '../../../course.dart';

enum LessonLockAction {
  proceed,
  ignoreTap,
  showPaywall,
}

class RoadmapNodeActionHelper {
  const RoadmapNodeActionHelper._();

  static bool _canTapLesson(LessonEntity lesson) => lesson.roadmapProgress != ProcessEnum.notStarted || kDebugMode;

  @visibleForTesting
  static LessonLockAction resolveLessonLockAction({
    required bool isLocked,
    required ProcessEnum progress,
  }) {
    if (!isLocked) return LessonLockAction.proceed;
    if (progress == ProcessEnum.notStarted) return LessonLockAction.ignoreTap;
    if (progress == ProcessEnum.inProgress) return LessonLockAction.showPaywall;
    return LessonLockAction.proceed;
  }

  static bool _handlePaywall(BuildContext context, LessonEntity lesson, bool isLocked) {
    if (!isLocked) return true;
    final isUserPremium = context.read<ProfileCubit>().state.user.iapSubscriptions.isNotEmpty;
    if (isUserPremium) return true;

    final trackingData = CourseTrackingData.fromCourseId(context, lesson.courseId);
    AppDI.injector.get<IapCubit>().setPaywallEntryPoint(
      PaywallEntryPoint.courseRoadmap,
      trackingData: trackingData,
    );
    PaywallRoute().push(context);
    return false;
  }

  static void _startRoleplay(BuildContext context, LessonEntity lesson) {
    AppDI.injector.get<RoleplayCubit>()
      ..reset()
      ..setCurrentLesson(lesson)
      ..loadLearningItem(lesson.learningItemId, estimateCompleTime: lesson.estimateCompleTime);
    context.read<RoleplayPointCubit>().reset();
    RoleplayIntroRoute().go(context);
  }

  static void _startOutputPractice(BuildContext context, LessonEntity lesson) {
    final roadmap = context.read<CourseRoadmapCubit>().state.roadmap;
    final sectionId = resolveOutputPracticeSectionId(roadmap, lesson);
    if (sectionId.isEmpty) return;
    final trackingData = CourseLessonTrackingData.fromLesson(context, lesson);
    final isPremium = context.read<ProfileCubit>().state.user.isPremium;

    OutputPracticeIntroSheet.show(
      context,
      lesson: lesson,
      sectionId: sectionId,
      isPremium: isPremium,
      trackingData: trackingData,
      onStart: () {
        AppDI.injector.get<OutputPracticeCubit>()
          ..reset()
          ..preloadEntry(
            lesson: lesson,
            sectionId: sectionId,
          );

        OutputPracticeRoute(sectionId: sectionId).push(context);
      },
    );
  }

  @visibleForTesting
  static String resolveOutputPracticeSectionId(RoadmapEntity roadmap, LessonEntity lesson) {
    for (final level in roadmap.levels) {
      for (final node in level.nodes) {
        if (node.output.id == lesson.id || node.outputId == lesson.id) {
          return node.id;
        }
      }
    }
    return '';
  }

  static CourseLevel _resolveCourseLevel(RoadmapEntity roadmap, LessonEntity lesson, CourseLevel fallback) {
    for (final level in roadmap.levels) {
      if (level.roadmapLessonsList.any((item) => item.isSameLesson(lesson))) {
        return level.level;
      }
    }
    return fallback;
  }

  static LessonEntity? _resolveLastInProgressLesson(RoadmapEntity roadmap) {
    return roadmap.lastInProgressLesson ?? roadmap.displayLessons.firstOrNull;
  }

  static void _startLessonAction(
    BuildContext context,
    LessonEntity lesson,
    CourseRoadmapState state, {
    bool? isLocked,
  }) {
    if (lesson.id.isEmpty) return;
    context.read<CourseRoadmapCubit>().setCurrentLesson(lesson);

    final paywallConfig = AppService.instance.remoteConfigService.paywallConfig;
    final lessonIsLocked = isLocked ?? state.roadmap.isLessonLocked(lesson, paywallConfig);
    final lockAction = resolveLessonLockAction(
      isLocked: lessonIsLocked,
      progress: lesson.roadmapProgress,
    );
    if (lockAction == LessonLockAction.ignoreTap) return;
    if (!_canTapLesson(lesson)) return;
    if (lockAction == LessonLockAction.showPaywall && !_handlePaywall(context, lesson, lessonIsLocked)) return;

    final trackingData = CourseLessonTrackingData.fromLesson(context, lesson);
    if (trackingData != null) {
      AppService.instance.appTrackingService.trackRoadmapItemClick(
        trackingData,
        itemType: lesson.type.trackingName,
      );
    }

    switch (lesson.type) {
      case LessonType.roleplay:
        _startRoleplay(context, lesson);
        return;
      case LessonType.lesson:
        if (lesson.keypoints.isEmpty) return;
        RoadmapDetailPopup.show(
          context,
          lesson: lesson,
          courseLevel: _resolveCourseLevel(state.roadmap, lesson, state.currentCourseLevel),
        );
        return;
      case LessonType.output:
        _startOutputPractice(context, lesson);
        return;
      case LessonType.unknown:
        return;
    }
  }

  static void startLessonAction(BuildContext context, LessonEntity lesson, {bool? isLocked}) {
    final state = context.read<CourseRoadmapCubit>().state;
    _startLessonAction(context, lesson, state, isLocked: isLocked);
  }

  static void startLastInProgressAction(BuildContext context) {
    final state = context.read<CourseRoadmapCubit>().state;
    final lesson = _resolveLastInProgressLesson(state.roadmap);
    if (lesson == null) return;
    _startLessonAction(context, lesson, state);
  }
}

class RoadmapNodeTimeline extends StatelessWidget {
  final List<LessonEntity> items;
  final bool enableSequentialUnlock;
  final Set<String> lockedLessonKeys;

  const RoadmapNodeTimeline({
    super.key,
    required this.items,
    this.enableSequentialUnlock = true,
    this.lockedLessonKeys = const {},
  });

  @override
  Widget build(BuildContext context) {
    final displayItems = items.applySequentialUnlock(enableAutoUnlock: enableSequentialUnlock);
    return Column(
      children: List.generate(displayItems.length, (index) {
        final lesson = displayItems[index];
        final isLocked = lockedLessonKeys.contains(lesson.roadmapKey);
        return RoadmapTimelineItem(
          lesson: lesson,
          isFirst: index == 0,
          isLast: index == displayItems.length - 1,
          isLocked: isLocked,
        );
      }),
    );
  }
}

class RoadmapTimelineItem extends StatelessWidget {
  final LessonEntity lesson;
  final bool isFirst;
  final bool isLast;
  final bool isLocked;

  const RoadmapTimelineItem({
    super.key,
    required this.lesson,
    required this.isFirst,
    required this.isLast,
    required this.isLocked,
  });

  @override
  Widget build(BuildContext context) {
    return TimelineTile(
      isFirst: isFirst,
      isLast: isLast,
      alignment: TimelineAlign.start,
      indicatorStyle: IndicatorStyle(
        width: 54.w,
        height: 54.w,
        padding: EdgeInsets.zero,
        indicator: RoadmapNodeIndicator(lesson: lesson),
      ),
      beforeLineStyle: const LineStyle(
        color: AppCustomColor.borderSecondary,
        thickness: 2.0,
        dashLength: 4.0,
        dashSpacing: 2.0,
        isDashed: true,
      ),
      afterLineStyle: const LineStyle(
        color: AppCustomColor.borderSecondary,
        thickness: 2.0,
        dashLength: 4.0,
        dashSpacing: 2.0,
        isDashed: true,
      ),
      endChild: Padding(
        padding: EdgeInsets.only(left: 16.w, top: 10.h, bottom: 10.h),
        child: RoadmapNodeContent(
          lesson: lesson,
          isLocked: isLocked,
        ),
      ),
    );
  }
}
