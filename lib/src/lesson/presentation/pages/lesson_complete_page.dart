part of '../../lesson.dart';

class LessonCompletePage extends StatefulWidget {
  const LessonCompletePage({super.key});

  @override
  State<LessonCompletePage> createState() => _LessonCompletePageState();
}

class _LessonCompletePageState extends State<LessonCompletePage> with SingleTickerProviderStateMixin {
  late final AnimationController _lottieController;
  CourseLessonTrackingData? _trackingData;
  bool _hasShownFeedbackPopup = false;

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _trackingData ??= _resolveTrackingData();
      if (_trackingData != null) {
        AppService.instance.appTrackingService.trackLessonFinishScrView(_trackingData!);
      }
      context.read<FeedbackCubit>().loadUserFeedbacks();
    });
  }

  CourseLessonTrackingData? _resolveTrackingData() {
    final keypointTracking = KeypointTrackingData.fromContext();
    if (keypointTracking != null) {
      return CourseLessonTrackingData(
        skillset: keypointTracking.skillset,
        course: keypointTracking.course,
        lesson: keypointTracking.lesson,
      );
    }

    final lesson = AppDI.injector.get<CourseLessonCubit>().state.selectedLesson;
    if (lesson.id.isEmpty) return null;
    return CourseLessonTrackingData.fromLesson(context, lesson);
  }

  @override
  void dispose() {
    _lottieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        body: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: Lottie.asset(
                  AppAsset.lottie.congratulations,
                  controller: _lottieController,
                  onLoaded: (composition) {
                    _lottieController
                      ..duration = composition.duration
                      ..forward();
                  },
                  fit: BoxFit.cover,
                  repeat: false,
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            AppAsset.icons.app.icTick.path,
                            width: 50.w,
                            height: 50.w,
                          ),
                          24.verticalSpace,
                          AppText(
                            context.text.exercise.exerciseLessonCompleteTitle.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: AppStyle.text12.copyWith(
                              color: AppCustomColor.textTertiary,
                              fontWeight: FontWeight.w600,
                              height: 1.75,
                            ),
                          ),
                          4.verticalSpace,
                          BlocSelector<CourseLessonCubit, CourseLessonState, String>(
                            selector: (state) => state.selectedLesson.title.text,
                            builder: (context, title) {
                              return AppText(
                                title,
                                maxLines: 2,
                                textAlign: TextAlign.center,
                                style: AppStyle.text20.copyWith(
                                  color: AppCustomColor.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  height: 1.5,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  LessonCompletionPrimaryButton(
                    label: context.text.exercise.exerciseCompleteLessonButton,
                    onPressed: () {
                      final bool isLastLessonInLevel = context.read<CourseRoadmapCubit>().state.isLastLessonInLevel;
                      if (isLastLessonInLevel) {
                        BadgeCompleteRoute().go(context);
                        return;
                      }
                      context.back();
                    },
                    margin: EdgeInsets.only(bottom: 16.h, top: 16.h),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
