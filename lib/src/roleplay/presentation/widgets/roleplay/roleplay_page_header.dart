part of '../../../roleplay.dart';

class RoleplayPageHeader extends StatelessWidget {
  final bool useLightContent;
  final String title;

  const RoleplayPageHeader({
    super.key,
    required this.useLightContent,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final Color textColor = useLightContent ? AppCustomColor.textWhite : AppCustomColor.textPrimary;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 20.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _RoleplayBackButton(isLight: useLightContent),
          12.horizontalSpace,
          AppText(
            title,
            maxLines: 2,
            style: AppStyle.text16.copyWith(
              fontWeight: FontWeight.w700,
              color: textColor,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleplayBackButton extends StatelessWidget {
  final bool isLight;

  const _RoleplayBackButton({required this.isLight});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        final roleplayState = AppDI.injector.get<RoleplayCubit>().state;
        final trackingData = RoleplayTrackingData.fromContext();
        AppDI.injector.get<CourseRoadmapCubit>().setRoadmapSource('nav_course');
        if (trackingData != null) {
          AppService.instance.appTrackingService.trackRoleplayConvExitClick(trackingData);
        }
        final courseId = trackingData?.course.id ?? roleplayState.currentLesson.courseId;
        final lessonId = trackingData?.lesson.id ?? roleplayState.currentLesson.id;
        context.read<FeedbackCubit>().setIncompleteFeedbackPrompt(
          entry: FeedbackEntry.roleplay,
          courseId: courseId,
          lessonId: lessonId,
        );

        CourseRoadmapRoute().go(context);
        context.read<FeedbackCubit>().loadUserFeedbacks();
      },
      icon: Icon(
        FontAwesomeIcons.xmark,
        size: 18.w,
        color: isLight ? Colors.white : AppCustomColor.textPrimary,
      ),
      padding: EdgeInsets.zero,
      splashRadius: 12.r,
    );
  }
}
