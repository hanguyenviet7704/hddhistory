part of '../../../course.dart';

class CourseRoadmapTimeline extends StatelessWidget {
  final List<LessonEntity> lessons;
  final CourseLevel courseLevel;
  final int lockedLessonStartIndex;
  const CourseRoadmapTimeline({
    super.key,
    required this.lessons,
    required this.courseLevel,
    required this.lockedLessonStartIndex,
  });

  void _onLessonTap(
    BuildContext context, {
    required LessonEntity targetLesson,
    required bool isLocked,
    required LessonEntity roleplay,
  }) {
    if (targetLesson.progess == ProcessEnum.notStarted && !kDebugMode) return;

    if (targetLesson.type == LessonType.lesson) {
      final trackingData = CourseLessonTrackingData.fromLesson(context, targetLesson);
      if (trackingData != null) {
        AppService.instance.appTrackingService.trackRoadmapItemClick(
          trackingData,
          itemType: 'lesson',
        );
      }
    }

    final isUserPremium = context.read<ProfileCubit>().state.user.iapSubscriptions.isNotEmpty;
    if (isLocked && !isUserPremium) {
      final trackingData = CourseTrackingData.fromCourseId(context, targetLesson.courseId);
      AppDI.injector.get<IapCubit>().setPaywallEntryPoint(
        PaywallEntryPoint.courseRoadmap,
        trackingData: trackingData,
      );
      PaywallRoute().push(context);
      return;
    }

    switch (targetLesson.type) {
      case LessonType.lesson:
        if (roleplay.id.isNotEmpty) {
          context.read<ProgressCubit>().loadUserProgressLesson(lessonId: roleplay.id);
        }
        context.read<CourseLessonCubit>()
          ..reset()
          ..loadLesson(targetLesson.id);
        LessonListRoute().go(context);
        context.read<CourseRoadmapCubit>()
          ..setCurrentCourseLevel(courseLevel)
          ..setCurrentLesson(targetLesson);
        break;
      case LessonType.roleplay:
        AppDI.injector.get<RoleplayCubit>()
          ..reset()
          ..setCurrentLesson(targetLesson)
          ..loadLearningItem(targetLesson.learningItemId, estimateCompleTime: targetLesson.estimateCompleTime);
        context.read<RoleplayPointCubit>().reset();
        RoleplayIntroRoute().go(context);
        break;
      case LessonType.output:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (lessons.isEmpty) {
      return Container(
        padding: EdgeInsets.all(32.w),
        decoration: BoxDecoration(
          color: AppCustomColor.backgroundWhite,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Center(
          child: AppText(
            context.text.courseroadmap.noRoadmapAvailable,
            style: AppStyle.text14.copyWith(
              color: AppCustomColor.textSecondary,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundWhite,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppCustomColor.borderDefault,
            blurRadius: 4,
            offset: const Offset(0, 0),
          ),
        ],
      ),

      child: Column(
        children: List.generate(lessons.length, (index) {
          final lesson = lessons[index];
          final isFirst = index == 0;
          final isLast = index == lessons.length - 1;
          final isLocked = lockedLessonStartIndex >= 0 && index >= lockedLessonStartIndex;

          return TimelineTile(
            isFirst: isFirst,
            isLast: isLast,
            alignment: TimelineAlign.start,
            indicatorStyle: IndicatorStyle(
              width: 32.w,
              height: 32.w,
              padding: EdgeInsets.zero,
              indicator: TimelineIndicator(progess: lesson.progess),
              // indicator: TimelineIndicator(process: ProcessEnum.done),
            ),
            beforeLineStyle: LineStyle(
              color: AppCustomColor.borderSecondary,
              thickness: 2.0,
            ),
            afterLineStyle: LineStyle(
              color: AppCustomColor.borderSecondary,
              thickness: 2.0,
            ),
            endChild: Padding(
              padding: EdgeInsets.only(
                left: 16.w,
                bottom: 8.h,
                top: 8.h,
              ),
              child: LessonKeypointCard(
                keypoint: lesson.keypoints.isNotEmpty
                    ? lesson.keypoints.first
                    : KeypointEntity(
                        id: lesson.id,
                        title: lesson.title,
                        description: lesson.description,
                        estimateCompleTime: lesson.estimateCompleTime,
                        progess: lesson.progess,
                      ),
                onTap: () => _onLessonTap(
                  context,
                  targetLesson: lesson,
                  isLocked: isLocked,
                  roleplay: lessons.lessonRolePlay(lesson.id),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
