part of '../../lesson.dart';

class KeypointCompletePage extends StatefulWidget {
  const KeypointCompletePage({super.key});

  @override
  State<KeypointCompletePage> createState() => _KeypointCompletePageState();
}

class _KeypointCompletePageState extends State<KeypointCompletePage> {
  bool _hasShownFeedbackPopup = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final trackingData = KeypointTrackingData.fromContext();
      if (trackingData == null) return;
      AppService.instance.appTrackingService.trackKeypointFinishScrView(trackingData);
      context.read<FeedbackCubit>().loadUserFeedbacks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentLesson = context.select((CourseLessonCubit cubit) => cubit.state.selectedLesson);
    final nextLesson = context.select(
      (CourseRoadmapCubit cubit) => cubit.state.roadmap.nextLessonAfter(currentLesson),
    );

    return BlocListener<FeedbackCubit, FeedbackState>(
      listenWhen: (previous, current) => previous.status != current.status && current.status == FeedbackStatus.success,
      listener: (context, state) {
        if (_hasShownFeedbackPopup) return;
        if (state.userFeedback.userHasKeypointFeedbackComplete) return;

        final keypointTracking = KeypointTrackingData.fromContext();
        String courseId = '';
        String lessonId = '';
        String keypointId = '';
        if (keypointTracking != null) {
          courseId = keypointTracking.course.id;
          lessonId = keypointTracking.lesson.id;
          keypointId = keypointTracking.keypoint.id;
        } else {
          final lessonState = AppDI.injector.get<CourseLessonCubit>().state;
          courseId = lessonState.selectedLesson.courseId;
          lessonId = lessonState.selectedLesson.id;
          keypointId = lessonState.currentKeypointId;
        }

        if (courseId.isEmpty || lessonId.isEmpty || keypointId.isEmpty) return;
        _hasShownFeedbackPopup = true;
        FeedbackCompleteLessonPopup.show(
          context,
          entry: FeedbackEntry.keypoint,
          courseId: courseId,
          lessonId: lessonId,
          keypointId: keypointId,
        );
      },
      child: Scaffold(
        backgroundColor: AppCustomColor.backgroundWhite,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: CompletionHeaderCard(title: currentLesson.title.text),
                        ),
                      ),
                      if (nextLesson.id.isNotEmpty && nextLesson.title.text.isNotEmpty)
                        NextLessonCard(title: nextLesson.title.text),
                    ],
                  ),
                ),
              ),
              LessonCompletionPrimaryButton(
                label: context.text.exercise.exerciseCompleteKeypointSkipButton,
                onPressed: () {
                  BadgeProgressRoute().go(context);
                  Future.delayed(const Duration(milliseconds: 100), () {
                    AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.badgeProgress);
                  });
                },
                margin: EdgeInsets.only(bottom: 16.h, top: 16.h),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
