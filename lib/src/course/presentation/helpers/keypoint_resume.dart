part of '../../course.dart';

/// The lesson in [roadmap] that owns [keypointId], or null when the roadmap
/// hasn't loaded far enough to contain it yet (a cold-start resume races the
/// fetch, so callers keep their pending id and retry on the next emission).
LessonEntity? findLessonByKeypointId(RoadmapEntity roadmap, String keypointId) {
  if (keypointId.isEmpty) return null;
  for (final lesson in roadmap.flatLessons) {
    if (lesson.keypoints.any((keypoint) => keypoint.id == keypointId)) return lesson;
  }
  return null;
}

/// Opens [keypoint] of [lesson] — the one sequence that puts the app inside a
/// keypoint, extracted so the roadmap's Start CTA and the Live Activity resume
/// can't drift apart.
///
/// The ordering matters and is preserved from the Start CTA: learning items are
/// requested before the route is pushed (so [LessonPage] builds against a load
/// already in flight), and the roadmap's own selection is updated after the push
/// (it only feeds back-navigation and the roadmap's highlight).
///
/// Narration always starts: a keypoint is a page being read out, and a keypoint
/// with nothing to read is a no-op anyway (`LessonPage._syncAudioKeypoint`
/// returns early on `!keypoint.hasUsableAudio`), so there is nothing here for a
/// caller to decide.
void startKeypointLesson({
  required LessonCubit lessonCubit,
  required CourseLessonCubit courseLessonCubit,
  required CourseRoadmapCubit roadmapCubit,
  required BuildContext navContext,
  required LessonEntity lesson,
  required KeypointEntity keypoint,
  required CourseLevel courseLevel,
}) {
  if (lesson.id.isEmpty || keypoint.id.isEmpty) return;

  lessonCubit
    ..reset()
    ..loadAllLearningItems(keypointId: keypoint.id, isInit: true);
  courseLessonCubit
    ..setSelectedLesson(lesson)
    ..setCurrentKeypointId(keypoint.id)
    ..loadLesson(lesson.id);

  const LessonRoute().go(navContext);

  roadmapCubit
    ..setCurrentCourseLevel(courseLevel)
    ..setCurrentLesson(lesson);
}

/// Opens a keypoint of a lesson the user GENERATED — the same sequence as
/// [startKeypointLesson], minus the three steps that need a catalogue.
///
/// Kept beside its sibling rather than folded into it with a flag, because what
/// differs is not a variation on the flow but the absence of the things the flow
/// normally talks to:
///
/// - items are handed over rather than fetched (nothing serves them);
/// - `loadLesson` is skipped (there is no lesson row to refresh FROM — calling
///   it would 404 and blank `selectedLesson` out from under the reader);
/// - the roadmap is left alone (a generated lesson is on no roadmap, and writing
///   to it would move the highlight on the user's real course).
///
/// Everything after this point is the ordinary reader: same route, same deck,
/// same narration, same completion screen.
void startImportedKeypointLesson({
  required LessonCubit lessonCubit,
  required CourseLessonCubit courseLessonCubit,
  required BuildContext navContext,
  required UserLessonEntity userLesson,
  required int keypointIndex,
}) {
  final lesson = UserLessonCourseMapper.toLesson(userLesson);
  if (lesson.id.isEmpty || keypointIndex >= lesson.keypoints.length) return;

  final keypoint = lesson.keypoints[keypointIndex];

  lessonCubit
    ..reset()
    ..loadLocalLearningItems(
      UserLessonCourseMapper.learningItemsOf(userLesson, keypointIndex),
    );
  courseLessonCubit
    ..setSelectedLesson(lesson)
    ..setCurrentKeypointId(keypoint.id);

  const LessonRoute().go(navContext);

  // Claim the deck's route name — the observer can't be relied on to. This
  // `go` crosses INTO the course branch from the lesson's own roadmap, and a
  // quit mid-keypoint leaves the deck route stranded on top of that branch (a
  // branch page is never popped on a branch switch). Re-activating a branch
  // whose stack already matches the target fires NO navigator event (pinned in
  // user_lesson_roadmap_nav_test.dart), so the roadmap's PRIMARY name would
  // stay tracked and the floating nav pill would sit over the deck.
  Future.delayed(const Duration(milliseconds: 100), () {
    AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.lesson);
  });
}
