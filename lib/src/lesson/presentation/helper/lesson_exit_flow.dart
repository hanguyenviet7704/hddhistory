part of '../../lesson.dart';

String resolveLessonFlowCourseId({
  String lessonCourseId = '',
  String roadmapCourseId = '',
  String homeCourseId = '',
}) {
  if (lessonCourseId.isNotEmpty) return lessonCourseId;
  if (roadmapCourseId.isNotEmpty) return roadmapCourseId;
  return homeCourseId;
}

void syncHomeSelectionForLessonFlowCourse(String courseId) {
  if (courseId.isEmpty) return;

  final homeCubit = AppDI.injector.get<HomeCubit>();
  if (homeCubit.state.currentCourse.id == courseId) return;

  final resolvedCourse = homeCubit.state.skillsets.resolveCourseByCourseId(
    courseId,
    fallback: homeCubit.state.currentCourse,
  );
  if (resolvedCourse.id != courseId) return;

  homeCubit.selectCourseFromCourseId(courseId);
}

class LessonExitFlow {
  const LessonExitFlow._();

  static Future<void> open(
    BuildContext context, {
    Future<void> Function()? onBeforePopup,
  }) async {
    if (AppDI.injector.get<LessonCubit>().state.isShowResultOverlay) return;

    final trackingData = KeypointTrackingData.fromContext();
    if (trackingData != null) {
      final lessonState = AppDI.injector.get<LessonCubit>().state;
      final cardType = lessonState.currentLearningItem.type == LearningItemType.theory ? 'theory' : 'exercise';
      AppService.instance.appTrackingService.trackKeypointExitClick(
        trackingData,
        cardIndex: lessonState.currentLearningItemIndex,
        cardType: cardType,
      );
    }

    await onBeforePopup?.call();
    if (!context.mounted) return;

    ClosePopupLesson.show(
      context,
      onQuit: () => _handleQuit(context),
      onKeepLearning: () => context.back(),
    );
  }

  static void _handleQuit(BuildContext context) {
    final learningItem = AppDI.injector.get<LessonCubit>().state.currentLearningItem;
    // Quitting mid-lesson ends the keypoint session → tear down the Live
    // Activity + its return-nudge (the persistent card only makes sense while a
    // lesson is actually open).
    unawaited(AppDI.injector.get<LiveActivityService>().end());
    unawaited(cancelLiveActivityReturnNudge());
    context.back();

    final entry = learningItem.type == LearningItemType.roleplay ? FeedbackEntry.roleplay : FeedbackEntry.keypoint;
    _markIncompleteFeedbackPrompt(context, entry);

    if (learningItem.type != LearningItemType.roleplay) {
      final courseLessonState = AppDI.injector.get<CourseLessonCubit>().state;
      final roadmapState = AppDI.injector.get<CourseRoadmapCubit>().state;
      final homeState = AppDI.injector.get<HomeCubit>().state;
      final courseId = resolveLessonFlowCourseId(
        lessonCourseId: courseLessonState.selectedLesson.courseId,
        roadmapCourseId: roadmapState.roadmap.courseId,
        homeCourseId: homeState.currentCourse.id,
      );
      syncHomeSelectionForLessonFlowCourse(courseId);
      CourseRoadmapRoute().go(context);
      context.read<FeedbackCubit>()
        ..setActiveEntry(FeedbackEntry.keypoint)
        ..loadUserFeedbacks();
      return;
    }

    context.back();
    RoleplayIntroRoute().go(context);
  }

  static void _markIncompleteFeedbackPrompt(BuildContext context, FeedbackEntry entry) {
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
}
