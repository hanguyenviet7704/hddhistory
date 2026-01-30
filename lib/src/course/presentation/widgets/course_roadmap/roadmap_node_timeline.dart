part of '../../../course.dart';

class RoadmapNodeTimeline extends StatelessWidget {
  final List<LessonEntity> items;
  final bool enableSequentialUnlock;

  const RoadmapNodeTimeline({
    super.key,
    required this.items,
    this.enableSequentialUnlock = true,
  });

  @override
  Widget build(BuildContext context) {
    final displayItems = items.applySequentialUnlock(enableAutoUnlock: enableSequentialUnlock);
    return Column(
      children: List.generate(displayItems.length, (index) {
        return RoadmapTimelineItem(
          lesson: displayItems[index],
          isFirst: index == 0,
          isLast: index == displayItems.length - 1,
        );
      }),
    );
  }
}

class RoadmapTimelineItem extends StatelessWidget {
  final LessonEntity lesson;
  final bool isFirst;
  final bool isLast;

  const RoadmapTimelineItem({
    super.key,
    required this.lesson,
    required this.isFirst,
    required this.isLast,
  });

  bool _canTap(LessonEntity lesson) => lesson.roadmapProgress != ProcessEnum.notStarted || kDebugMode;

  bool _handlePaywall(BuildContext context, LessonEntity lesson, bool isLocked) {
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

  void _handleRoleplayTap(BuildContext context, LessonEntity lesson, bool isLocked) {
    if (!_canTap(lesson)) return;
    if (!_handlePaywall(context, lesson, isLocked)) return;

    AppDI.injector.get<RoleplayCubit>()
      ..reset()
      ..setCurrentLesson(lesson)
      ..loadLearningItem(lesson.learningItemId, estimateCompleTime: lesson.estimateCompleTime);
    context.read<RoleplayPointCubit>().reset();
    RoleplayIntroRoute().go(context);
  }

  void _handleLessonKeypointTap(
    BuildContext context,
    bool isLocked,
  ) {
    if (!_canTap(lesson)) return;
    if (!_handlePaywall(context, lesson, isLocked)) return;

    RoadmapDetailPopup.show(
      context,
      lesson: lesson,
      courseLevel: CourseLevel.level1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = true;
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
          onRoleplayTap: () => _handleRoleplayTap(context, lesson, isLocked),
          onKeypointTap: () => _handleLessonKeypointTap(context, isLocked),
        ),
      ),
    );
  }
}
