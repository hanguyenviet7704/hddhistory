part of '../../../course.dart';

class RoadmapNodeTimeline extends StatelessWidget {
  final List<LessonEntity> items;
  final List<LessonEntity> levelLessons;
  final int lockedLessonStartIndex;
  final CourseLevel courseLevel;
  final LessonEntity roleplay;

  const RoadmapNodeTimeline({
    super.key,
    required this.items,
    required this.levelLessons,
    required this.lockedLessonStartIndex,
    required this.courseLevel,
    required this.roleplay,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(items.length, (index) {
        return RoadmapTimelineItem(
          lesson: items[index],
          isFirst: index == 0,
          isLast: index == items.length - 1,
          levelLessons: levelLessons,
          lockedLessonStartIndex: lockedLessonStartIndex,
          courseLevel: courseLevel,
          roleplay: roleplay,
        );
      }),
    );
  }
}

class RoadmapTimelineItem extends StatelessWidget {
  final LessonEntity lesson;
  final bool isFirst;
  final bool isLast;
  final List<LessonEntity> levelLessons;
  final int lockedLessonStartIndex;
  final CourseLevel courseLevel;
  final LessonEntity roleplay;

  const RoadmapTimelineItem({
    super.key,
    required this.lesson,
    required this.isFirst,
    required this.isLast,
    required this.levelLessons,
    required this.lockedLessonStartIndex,
    required this.courseLevel,
    required this.roleplay,
  });

  bool get _isLocked {
    final flatIndex = levelLessons.indexWhere((l) => l.id == lesson.id);
    return flatIndex >= 0 && flatIndex >= lockedLessonStartIndex;
  }

  String get _defaultIconAsset {
    if (lesson.type == LessonType.roleplay) return AppAsset.svg.app.icSend;
    if (lesson.type == LessonType.lesson) return AppAsset.svg.app.icBook;
    return AppAsset.svg.app.icAim;
  }

  String? get _iconUrl {
    if (lesson.icon.url.isNotEmpty) return lesson.icon.url;
    if (lesson.lightIcon.url.isNotEmpty) return lesson.lightIcon.url;
    return null;
  }

  bool _canTap(LessonEntity lesson) => lesson.progess != ProcessEnum.notStarted || kDebugMode;

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
      courseLevel: courseLevel,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = _isLocked;
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 20.h),
      child: TimelineTile(
        isFirst: isFirst,
        isLast: isLast,
        alignment: TimelineAlign.start,
        indicatorStyle: IndicatorStyle(
          width: 54.w,
          height: 54.w,
          padding: EdgeInsets.zero,
          indicator: _RoadmapNodeIndicator(
            iconUrl: _iconUrl,
            defaultIconAsset: _defaultIconAsset,
            isLocked: isLocked,
          ),
        ),
        beforeLineStyle: const LineStyle(
          color: AppCustomColor.borderSecondary,
          thickness: 2.0,
          dotted: true,
          dotRadius: 2.0,
          dotSpacing: 6.0,
        ),
        afterLineStyle: const LineStyle(
          color: AppCustomColor.borderSecondary,
          thickness: 2.0,
          dotted: true,
          dotRadius: 2.0,
          dotSpacing: 6.0,
        ),
        endChild: Padding(
          padding: EdgeInsets.only(left: 16.w),
          child: RoadmapNodeContent(
            lesson: lesson,
            isLocked: isLocked,
            onRoleplayTap: () => _handleRoleplayTap(context, lesson, isLocked),
            onKeypointTap: () => _handleLessonKeypointTap(context, isLocked),
          ),
        ),
      ),
    );
  }
}
