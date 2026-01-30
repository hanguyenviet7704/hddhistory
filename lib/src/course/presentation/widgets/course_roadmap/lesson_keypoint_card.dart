part of '../../../course.dart';

class LessonKeypointCard extends StatelessWidget {
  final LessonEntity lesson;
  final LessonEntity lessonRolePlay;
  final bool premiumLesson;
  final CourseLevel courseLevel;
  final VoidCallback? onOverrideTap;

  const LessonKeypointCard({
    super.key,
    required this.lesson,
    required this.lessonRolePlay,
    required this.premiumLesson,
    required this.courseLevel,
    this.onOverrideTap,
  });

  Color get _textColor {
    switch (lesson.progess) {
      case ProcessEnum.done:
        return AppCustomColor.textPrimary;
      case ProcessEnum.inProgress:
        return AppCustomColor.brandPrimary300;
      case ProcessEnum.notStarted:
        return AppCustomColor.textSecondary;
    }
  }

  void _trackRoadmapItemClick(BuildContext context) {
    final trackingData = CourseLessonTrackingData.fromLesson(context, lesson);
    if (trackingData == null) return;
    AppService.instance.appTrackingService.trackRoadmapItemClick(
      trackingData,
      itemType: 'lesson',
    );
  }

  void _onTap(BuildContext context) {
    if (lesson.progess == ProcessEnum.notStarted && !kDebugMode) return;

    if (onOverrideTap != null) {
      onOverrideTap!();
      return;
    }

    if (lesson.type == LessonType.lesson) {
      _trackRoadmapItemClick(context);
    }

    bool isUserPremium = context.read<ProfileCubit>().state.user.iapSubscriptions.isNotEmpty;
    if (premiumLesson && !isUserPremium) {
      final trackingData = CourseTrackingData.fromCourseId(context, lesson.courseId);
      AppDI.injector.get<IapCubit>().setPaywallEntryPoint(
        PaywallEntryPoint.courseRoadmap,
        trackingData: trackingData,
      );
      PaywallRoute().push(context);
      return;
    }

    switch (lesson.type) {
      case LessonType.lesson:
        if (lessonRolePlay.id.isNotEmpty) {
          context.read<ProgressCubit>().loadUserProgressLesson(lessonId: lessonRolePlay.id);
        }
        context.read<CourseLessonCubit>()
          ..reset()
          ..loadLesson(lesson.id);
        LessonListRoute().go(context);
        context.read<CourseRoadmapCubit>()
          ..setCurrentCourseLevel(courseLevel)
          ..setCurrentLesson(lesson);
        break;

      case LessonType.roleplay:
        // if (lesson.progess == ProcessEnum.done && !kDebugMode) return;

        AppDI.injector.get<RoleplayCubit>()
          ..reset()
          ..setCurrentLesson(lesson)
          ..loadLearningItem(lesson.learningItemId, estimateCompleTime: lesson.estimateCompleTime);
        context.read<RoleplayPointCubit>().reset();
        RoleplayIntroRoute().go(context);
        break;

      case LessonType.output:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _onTap(context),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            constraints: BoxConstraints(minHeight: 44.h),
            decoration: BoxDecoration(
              color: AppCustomColor.backgroundWhite,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: lesson.progess == ProcessEnum.inProgress ? AppCustomColor.brandPrimary : AppCustomColor.borderDefault,
                width: lesson.progess == ProcessEnum.inProgress ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppCustomColor.borderDefault, // WhiteOnGray shadow from Figma
                  blurRadius: 4,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: AppText(
              lesson.title.text,
              style: AppStyle.text14.copyWith(
                fontWeight: FontWeight.w500,
                color: _textColor,
                height: 1.75,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
