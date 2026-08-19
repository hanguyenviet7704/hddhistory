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
    String mode = 'read',
    Future<void> Function()? onBeforePopup,
  }) async {
    if (AppDI.injector.get<LessonCubit>().state.isShowResultOverlay) return;

    // keypoint_read_exit_click tracking removed per request.

    await onBeforePopup?.call();
    if (!context.mounted) return;

    ClosePopupLesson.show(
      context,
      mode: mode,
      onQuit: () => _handleQuit(context),
      onKeepLearning: () => context.back(),
    );
  }

  static void _handleQuit(BuildContext context) {
    final learningItem = AppDI.injector.get<LessonCubit>().state.currentLearningItem;
    // Read BEFORE the pop below: the cubit is created per lesson route and
    // provided into that subtree, so once this popup and the lesson are gone
    // there is nothing left to ask.
    final wasWalled = _wasWalled(context);
    // Quitting mid-lesson ends the keypoint session → tear down the Live
    // Activity + its return-nudge (the persistent card only makes sense while a
    // lesson is actually open).
    unawaited(AppDI.injector.get<LiveActivityService>().end());
    unawaited(cancelLiveActivityReturnNudge());
    context.back();

    final entry = learningItem.type == LearningItemType.roleplay ? FeedbackEntry.roleplay : FeedbackEntry.keypoint;
    // Only ask people who CHOSE to leave. A reader stopped by the daily-quota
    // locked card or the mid-lesson paywall gate ran out of content — they
    // pressed the X because there was nothing left to read, not because they
    // wanted out, and "why did you quit?" reads as blaming them for a wall we
    // put there. Their answer would also poison the data the prompt exists to
    // collect.
    if (!wasWalled) {
      _markIncompleteFeedbackPrompt(context, entry);
    }

    // A lesson the user generated has a roadmap of its own — quitting it lands
    // there, the same way quitting a catalogue lesson lands on its course.
    // Checked before the roadmap branch below, which reads catalogue ids and
    // would otherwise drop them into a course they were not studying.
    final selectedLesson =
        AppDI.injector.get<CourseLessonCubit>().state.selectedLesson;
    if (selectedLesson.isImported) {
      final userLessonId = UserLessonCourseMapper.lessonIdOf(selectedLesson.id);
      final destinationRouteName = userLessonId.isEmpty ? RouteNamed.myLessons : RouteNamed.lessonReader;
      if (userLessonId.isEmpty) {
        const MyLessonsRoute().go(context);
      } else {
        LessonReaderRoute(userLessonId).go(context);
      }

      // Claim the destination's name, as keypoint_complete_page does on the
      // same exits: this cross-branch `go` usually re-activates the LIBRARY
      // branch whose stack ALREADY ends at the destination, which fires no
      // navigator event — the nav pill on the roadmap only survived because
      // the quit popup's pop happened to leave the root shell's (primary)
      // name behind.
      Future.delayed(const Duration(milliseconds: 100), () {
        AppDI.injector.get<PageCubit>().setCurrentRouteName(destinationRouteName);
      });

      return;
    }

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

  /// Whether this lesson put a wall in front of the reader.
  ///
  /// Tolerates the cubit being absent rather than requiring callers to know:
  /// [open] serves roleplay too, and a roleplay route has no [KeypointCardCubit]
  /// in its tree — reading one there would throw where the honest answer is
  /// simply "no wall", roleplay having no quota gate.
  static bool _wasWalled(BuildContext context) {
    try {
      return context.read<KeypointCardCubit>().wasPaywallCapped;
    } catch (_) {
      return false;
    }
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
