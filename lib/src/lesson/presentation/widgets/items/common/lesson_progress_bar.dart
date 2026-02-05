part of '../../../../lesson.dart';

class LessonProgressBar extends StatelessWidget {
  const LessonProgressBar({
    super.key,
  });

  void _markIncompleteFeedbackPrompt(BuildContext context, FeedbackEntry entry) {
    final trackingData = KeypointTrackingData.fromContext();
    String courseId = '';
    String lessonId = '';
    String keypointId = '';
    if (trackingData != null) {
      courseId = trackingData.course.id;
      lessonId = trackingData.lesson.id;
      keypointId = trackingData.keypoint.id;
    } else {
      final lessonState = AppDI.injector.get<CourseLessonCubit>().state;
      courseId = lessonState.selectedLesson.courseId;
      lessonId = lessonState.selectedLesson.id;
      keypointId = lessonState.currentKeypointId;
    }

    if (courseId.isEmpty || lessonId.isEmpty || keypointId.isEmpty) return;
    context.read<FeedbackCubit>().setIncompleteFeedbackPrompt(
      entry: entry,
      courseId: courseId,
      lessonId: lessonId,
      keypointId: keypointId,
    );
  }

  void _onCloseTap(BuildContext context) {
    bool isShowResultOverlay = AppDI.injector.get<LessonCubit>().state.isShowResultOverlay;
    if (isShowResultOverlay) return;

    final trackingData = KeypointTrackingData.fromContext();
    if (trackingData != null) {
      AppService.instance.appTrackingService.trackKeypointExitClick(trackingData);
    }

    ClosePopupLesson.show(
      context,
      onQuit: () {
        LearningItemEntity learningItem = AppDI.injector.get<LessonCubit>().state.currentLearningItem;
        context.back();
        final entry = learningItem.type == LearningItemType.roleplay ? FeedbackEntry.roleplay : FeedbackEntry.keypoint;
        _markIncompleteFeedbackPrompt(context, entry);

        if (learningItem.type != LearningItemType.roleplay) {
          // context.back();
          CourseRoadmapRoute().go(context);
          context.read<FeedbackCubit>()
            ..setActiveEntry(FeedbackEntry.keypoint)
            ..loadUserFeedbacks();
          return;
        }
        context.back();
        RoleplayIntroRoute().go(context);
      },
      onKeepLearning: () {
        context.back();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 12.h),
      child: Row(
        children: [
          20.horizontalSpace,
          InkWell(
            onTap: () => _onCloseTap(context),
            child: Icon(
              Icons.close_rounded,
              color: const Color(0xFF0D121C), // Brand/Brand/Primary/300
              size: 20.sp,
            ),
          ),
          10.horizontalSpace,
          Expanded(
            child: BlocSelector<LessonCubit, LessonState, double>(
              selector: (state) => state.progress,
              builder: (context, progress) {
                return LinearPercentIndicator(
                  animation: true,
                  animationDuration: 500,
                  animateFromLastPercent: true,
                  lineHeight: 10.h,
                  percent: progress,
                  backgroundColor: const Color(0xFFE3E8EF), // Neutral/200
                  progressColor: const Color(0xFF0D121C), // Brand/Brand/Primary/300
                  barRadius: Radius.circular(30.r),
                  padding: EdgeInsets.zero,
                );
              },
            ),
          ),

          // BlocSelector<LessonCubit, LessonState, LearningItemType>(
          //   selector: (state) => state.currentLearningItem.type,
          //   builder: (context, learningItemType) {
          //     if (learningItemType != LearningItemType.roleplay) {
          //       return const SizedBox.shrink();
          //     }

          //     return Row(
          //       children: [
          //         20.horizontalSpace,
          //         LessonTimeBanner(onDone: () => context.read<ExerciseCubit>().nextQuestion()),
          //       ],
          //     );
          //   },
          // ),
          20.horizontalSpace,
        ],
      ),
    );
  }
}
