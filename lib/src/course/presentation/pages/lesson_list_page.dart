part of '../../course.dart';

class LessonListPage extends StatefulWidget {
  const LessonListPage({super.key});

  @override
  State<LessonListPage> createState() => _LessonListPageState();
}

class _LessonListPageState extends State<LessonListPage> {
  bool _didTrackScrView = false;

  LessonExplainTrackingData? _buildTrackingData(LessonEntity lesson) {
    return LessonExplainTrackingData.fromLesson(
      context,
      lesson,
      source: 'lesson_keypoint',
    );
  }

  void _trackLessonKeypointScrView(LessonEntity lesson) {
    if (_didTrackScrView) return;
    final trackingData = _buildTrackingData(lesson);
    if (trackingData == null) return;
    AppService.instance.appTrackingService.trackLessonKeypointScrView(trackingData);
    _didTrackScrView = true;
  }

  void _trackLessonKeypointExit(LessonEntity lesson) {
    final trackingData = _buildTrackingData(lesson);
    if (trackingData == null) return;
    AppService.instance.appTrackingService.trackLessonKeypointExit(trackingData);
  }

  void _trackLessonKeypointClick(LessonEntity lesson, KeypointEntity keypoint) {
    final trackingData = _buildTrackingData(lesson);
    if (trackingData == null) return;
    AppService.instance.appTrackingService.trackLessonKeypointClick(
      trackingData,
      keypoint: keypoint,
    );
  }

  void _showTutorialIfNeeded(LessonEntity lesson) {
    if (!context.mounted) return;
    final isFirstTime = context.read<UserCubit>().state.isFirstTimeUserAccessLessonList;
    if (!isFirstTime) return;

    context.read<UserCubit>().setIsFirstTimeUserAccessLessonList(false);
    final trackingData = _buildTrackingData(lesson);
    LessonExplainPopup.show(context, trackingData: trackingData);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (isPop, result) {
        if (!isPop) return;
        final lesson = context.read<CourseLessonCubit>().state.selectedLesson;
        _trackLessonKeypointExit(lesson);
      },
      child: Scaffold(
        backgroundColor: AppCustomColor.backgroundWhite,
        body: SafeArea(
          child: BlocListener<CourseLessonCubit, CourseLessonState>(
            listenWhen: (previous, current) => previous.selectedLesson.id != current.selectedLesson.id,
            listener: (context, state) {
              if (state.selectedLesson.id.isEmpty) return;
              _trackLessonKeypointScrView(state.selectedLesson);
              _showTutorialIfNeeded(state.selectedLesson);
            },
            child: BlocBuilder<CourseLessonCubit, CourseLessonState>(
              buildWhen: (previous, current) => previous.status != current.status || previous.selectedLesson != current.selectedLesson,
              builder: (context, state) {
                if (state.status == CourseLessonStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.status == CourseLessonStatus.failure) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.w),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64.sp,
                            color: AppCustomColor.errorRed,
                          ),
                          SizedBox(height: 16.h),
                          AppText(
                            context.text.allcourse.errorOccurred,
                            style: AppStyle.text16.copyWith(
                              color: AppCustomColor.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final LessonResultEntity currentLessonResult = context.read<ProgressCubit>().state.currentLessonResult;
                final lesson = state.updateLessonWithResults(currentLessonResult);

                // Check if lesson data is empty (id is empty means no data loaded)
                if (lesson.id.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.w),
                      child: AppText(
                        context.text.allcourse.noLessonData,
                        style: AppStyle.text16.copyWith(
                          color: AppCustomColor.textSecondary,
                        ),
                      ),
                    ),
                  );
                }

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Lesson header (title, type, duration)
                        LessonListHeader(lesson: lesson),
                        16.verticalSpace,
                        // Lesson description
                        AppText(
                          lesson.description.text,
                          maxLines: 20,
                          textAlign: TextAlign.justify,
                          style: AppStyle.text14.copyWith(color: AppCustomColor.textSecondary),
                        ),
                        12.verticalSpace,

                        // Key points section header
                        const KeypointsSectionHeader(),
                        16.verticalSpace,

                        // Key points list
                        if (lesson.keypoints.isEmpty)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 32.w),
                            child: Center(
                              child: AppText(
                                context.text.allcourse.noKeypointsAvailable,
                                style: AppStyle.text14.copyWith(
                                  color: AppCustomColor.textTertiary,
                                ),
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: lesson.keypoints.length,
                            separatorBuilder: (context, index) => 16.verticalSpace,
                            itemBuilder: (context, index) {
                              final keypoint = lesson.keypoints[index];

                              return KeypointCard(
                                keypoint: keypoint,
                                onTap: () {
                                  _trackLessonKeypointClick(lesson, keypoint);
                                  context.read<LessonCubit>()
                                    ..reset()
                                    ..loadAllLearningItems(keypointId: keypoint.id, isInit: true);
                                  context.read<CourseLessonCubit>().setCurrentKeypointId(keypoint.id);
                                  LessonRoute().go(context);
                                },
                              );
                            },
                          ),

                        32.verticalSpace,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
