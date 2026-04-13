part of '../../lesson.dart';

class LessonExitFlow {
  const LessonExitFlow._();

  static Future<void> open(
    BuildContext context, {
    Future<void> Function()? onBeforePopup,
  }) async {
    if (AppDI.injector.get<LessonCubit>().state.isShowResultOverlay) return;

    final trackingData = KeypointTrackingData.fromContext();
    if (trackingData != null) {
      AppService.instance.appTrackingService.trackKeypointExitClick(trackingData);
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
    context.back();

    final entry = learningItem.type == LearningItemType.roleplay ? FeedbackEntry.roleplay : FeedbackEntry.keypoint;
    _markIncompleteFeedbackPrompt(context, entry);

    if (learningItem.type != LearningItemType.roleplay) {
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
