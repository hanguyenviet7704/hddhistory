part of '../../../course.dart';

enum CourseRoadmapStatus { initial, loading, success, failure }

@freezed
abstract class CourseRoadmapState with _$CourseRoadmapState {
  const factory CourseRoadmapState({
    @Default(CourseRoadmapStatus.initial) CourseRoadmapStatus status,
    @Default(RoadmapEntity()) RoadmapEntity roadmap,
    @Default(CourseLevelProgressEntity()) CourseLevelProgressEntity currentLevelProgress,
    @Default(CourseLevel.level1) CourseLevel currentCourseLevel,
    @Default(LessonEntity()) LessonEntity currentLesson,
    @Default('nav_course') String roadmapSource,
    String? errorMessage,
  }) = _CourseRoadmapState;

  factory CourseRoadmapState.initial() => CourseRoadmapState();

  factory CourseRoadmapState.fromJson(Map<String, dynamic> json) => _$CourseRoadmapStateFromJson(json);
}

extension CourseRoadmapStateExtension on CourseRoadmapState {
  bool get isCompleted => roadmap.levels.every((level) => level.isCompleted);
  RoadmapLevelEntity get currentLevelOpen =>
      roadmap.levels.firstWhere((level) => !level.isCompleted, orElse: () => RoadmapLevelEntity());
  RoadmapLevelEntity get currentLevel => roadmap.levels.firstWhere((level) => level.level == currentCourseLevel);
  List<LessonEntity> get currentLevelLessons => currentLevel.lessonList.where((lesson) => lesson.type == LessonType.lesson).toList();
  bool get isLastLessonInLevel {
    if (currentLevelLessons.isEmpty) return false;
    return currentLevelLessons.last.id == currentLesson.id;
  }
}

/// True when a page showing the roadmap should trigger a (re)fetch:
/// - the roadmap is blank for a known course (a previous load failed or never
///   ran — e.g. splash routed here off hydrated state without fetching), or
/// - hydrated data is present but nothing was fetched this app session
///   (stale-by-default cache after cold start).
/// Never true while a load is in flight or when no course is known (that is a
/// genuine "pick a course" empty state, not a failure).
/// Kept as a pure function so the self-heal trigger is unit-testable
/// (mirrors [shouldSelfHealHomeData]).
bool shouldEnsureRoadmapReload(
  CourseRoadmapState state, {
  required bool hasLoadedThisSession,
}) {
  if (state.roadmap.courseId.isEmpty) return false;
  if (state.status == CourseRoadmapStatus.loading) return false;
  if (state.roadmap.levels.isEmpty) return true;
  return !hasLoadedThisSession;
}

/// Hydration restores the last PERSISTED state — including a `loading` status
/// captured if the process died mid-fetch. Nothing completes that phantom load
/// after a cold start, and [shouldEnsureRoadmapReload] treats `loading` as
/// "fetch in flight", so a hydrated `loading` would silently disable the
/// self-heal for the whole session (or leave an eternal spinner on an empty
/// roadmap). Normalize it back to `initial` on restore.
CourseRoadmapState normalizeHydratedRoadmapState(CourseRoadmapState state) =>
    state.status == CourseRoadmapStatus.loading ? state.copyWith(status: CourseRoadmapStatus.initial) : state;
