part of '../../lesson.dart';

class KeypointCompletePage extends StatefulWidget {
  const KeypointCompletePage({super.key});

  @override
  State<KeypointCompletePage> createState() => _KeypointCompletePageState();
}

class _KeypointCompletePageState extends State<KeypointCompletePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final trackingData = KeypointTrackingData.fromContext();
      if (trackingData == null) return;
      AppService.instance.appTrackingService.trackKeypointFinishScrView(trackingData);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCustomColor.backgroundWhite,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            AppAsset.images.app.keypointCompleteDecoration.path,
                            width: 267.w,
                            
                            fit: BoxFit.contain,
                          ),
                          24.verticalSpace,
                          AppText(
                            context.text.exercise.exerciseKeypointCompleteTitle.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: AppStyle.text12.copyWith(
                              color: AppCustomColor.textTertiary,
                              fontWeight: FontWeight.w600,
                              height: 1.75,
                            ),
                          ),
                          4.verticalSpace,
                          BlocSelector<CourseLessonCubit, CourseLessonState, String>(
                            selector: (state) => state.currentKeypoint.title.text,
                            builder: (context, title) {
                              return AppText(
                                title,
                                textAlign: TextAlign.center,
                                maxLines: 2,
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
                    24.verticalSpace,
                    BlocSelector<CourseRoadmapCubit, CourseRoadmapState, CourseLevelProgressEntity>(
                      selector: (state) => state.currentLevelProgress,
                      builder: (context, progress) {
                        if (progress.courseId.isEmpty) return const SizedBox.shrink();
                        return KeypointCompleteProgressCard(progress: progress);
                      },
                    ),
                  ],
                ),
              ),
            ),
            LessonCompletionPrimaryButton(
              label: context.text.exercise.exerciseCompleteKeypointSkipButton,
              onPressed: () {
                bool isAllOtherKeypointsCompleted = context.read<CourseLessonCubit>().state.isAllOtherKeypointsCompleted;
                if (!isAllOtherKeypointsCompleted) {
                  context.back();
                  return;
                }

                LessonCompleteRoute().go(context);
              },
              margin: EdgeInsets.only(bottom: 16.h, top: 16.h),
            ),
          ],
        ),
      ),
    );
  }
}
