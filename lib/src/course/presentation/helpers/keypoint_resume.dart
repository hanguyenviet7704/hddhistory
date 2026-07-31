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
