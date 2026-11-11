part of '../../../course.dart';

@lazySingleton
class CourseRoadmapCubit extends HydratedCubit<CourseRoadmapState> with CubitUseCaseHandlerMixin<CourseRoadmapState> {
  final GetRoadmapUseCase _getRoadmapUseCase;
  LessonEntity? _cachedLessonAction;

  /// Set when a loadRoadmap() succeeded during THIS app session. Hydration
  /// restores state but not this flag, so a hydrated roadmap counts as stale
  /// and gets one silent refresh on first page entry after cold start.
  bool _hasLoadedThisSession = false;
  Future<void>? _ensureInFlight;

  /// Keypoint a Live Activity / return-nudge tap asked to reopen, held until the
  /// roadmap has loaded enough to resolve it (see [CourseRoadmapPage]).
  ///
  /// Deliberately NOT part of the hydrated state: a resume request belongs to
  /// one tap, and persisting it would hijack the next cold start too.
  String _pendingResumeKeypointId = '';
  String get pendingResumeKeypointId => _pendingResumeKeypointId;

  void setPendingResumeKeypointId(String keypointId) => _pendingResumeKeypointId = keypointId;

  void clearPendingResumeKeypointId() => _pendingResumeKeypointId = '';

  /// The course id an EXPLICIT course-switch call to [loadRoadmap] (a
  /// `courseId` argument different from the one currently on screen — e.g.
  /// HomeCubit.selectCourseIndex when the user picks another course) is
  /// currently fetching. Null when nothing is in flight, or when the in-flight
  /// fetch is just a same-course refresh (pull-to-refresh, or
  /// [ensureRoadmapLoaded]'s silent cold-start self-heal).
  ///
  /// [loadRoadmap] does NOT clear `state.roadmap` when a fetch starts (see its
  /// doc), so `state.roadmap` stays on the previous course for the whole
  /// round-trip of a switch. CourseRoadmapPage reads this flag to show a
  /// "switching courses" overlay over that stale roadmap instead of leaving
  /// the switch silent — without also flagging an ordinary same-course
  /// refresh, which already has its own feedback (the pull-to-refresh
  /// spinner) or is meant to be invisible (the self-heal).
  ///
  /// Purely transient, like [_hasLoadedThisSession] — deliberately NOT part of
  /// the persisted/hydrated state: there is nothing meaningful to resume
  /// mid-fetch after a process restart, so it always starts null.
  String? _switchingToCourseId;
  bool get isSwitchingCourse => _switchingToCourseId != null;

  CourseRoadmapCubit(
    this._getRoadmapUseCase,
  ) : super(CourseRoadmapState.initial());

  /// Pinned so an obfuscated release build cannot rename the key this
  /// cubit's state is stored under — see [HydrateBlocService].
  @override
  String get storagePrefix => 'CourseRoadmapCubit';

  @override
  CourseRoadmapState fromJson(Map<String, dynamic> json) => normalizeHydratedRoadmapState(CourseRoadmapState.fromJson(json));

  @override
  Map<String, dynamic> toJson(CourseRoadmapState state) => state.toJson();

  void reset() {
    _hasLoadedThisSession = false;
    _ensureInFlight = null;
    _switchingToCourseId = null;
    emit(CourseRoadmapState.initial());
  }

  void setRoadmapSource(String source) => emit(state.copyWith(roadmapSource: source));

  void setCurrentLevelProgress(List<CourseLevelProgressEntity> courseLevelProgresses) async {
    if (state.roadmap.levels.isEmpty) return;
    final CourseLevelProgressEntity currentLevelProgress = courseLevelProgresses.firstWhere(
      (progress) => progress.level == state.currentCourseLevel && progress.courseId == state.roadmap.courseId,
      orElse: () => CourseLevelProgressEntity(),
    );
    emit(state.copyWith(currentLevelProgress: currentLevelProgress));
  }

  void setCurrentCourseLevel(CourseLevel level) => emit(state.copyWith(currentCourseLevel: level));

  void setCurrentLesson(LessonEntity lesson) {
    _cachedLessonAction = lesson;
    emit(state.copyWith(currentLesson: lesson));
  }

  LessonEntity? get cachedLessonAction => _cachedLessonAction;

  /// Self-heal + stale-refresh for pages that render the roadmap: fetches when
  /// the roadmap is blank for a known course (an earlier load failed or never
  /// ran — e.g. splash routed here off hydrated state) or when hydrated data
  /// hasn't been refreshed this session. No-op when data is fresh or a load is
  /// already running, so it's safe to call on every page mount and tab return.
  /// Mirrors [HomeCubit.ensureHomeDataLoaded]. Without this, a failed or
  /// skipped first load leaves the roadmap blank until the user
  /// pull-to-refreshes or restarts the app.
  Future<void> ensureRoadmapLoaded() {
    final inFlight = _ensureInFlight;
    if (inFlight != null) return inFlight;
    if (!shouldEnsureRoadmapReload(state, hasLoadedThisSession: _hasLoadedThisSession)) {
      return Future.value();
    }
    final future = loadRoadmap().whenComplete(() => _ensureInFlight = null);
    _ensureInFlight = future;
    return future;
  }

  Future<void> loadRoadmap({String courseId = ''}) async {
    // A genuine course switch is a non-empty explicit `courseId` argument that
    // differs from the course currently on screen — as opposed to a
    // same-course reload (bare `loadRoadmap()` calls from pull-to-refresh and
    // [ensureRoadmapLoaded]). Recorded BEFORE the `courseId` param gets
    // defaulted below so it only reflects an explicit switch request.
    final bool isCourseSwitch = courseId.isNotEmpty && courseId != state.roadmap.courseId;
    if (isCourseSwitch) _switchingToCourseId = courseId;

    if (courseId.isEmpty) {
      courseId = state.roadmap.courseId;
    }
    if (courseId.isEmpty) return;

    // Opening a course's roadmap is the universal "view" signal — record it so
    // the course surfaces in the search screen's "Recent" list.
    AppDI.injector.get<CourseCubit>().recordCourseView(courseId);

    await runUseCase<RoadmapEntity>(
      usecase: () => _getRoadmapUseCase(courseId),
      // Deliberately does NOT touch `roadmap` — a course switch keeps the
      // PREVIOUS course's roadmap in state for the whole round-trip (the page
      // dims it and overlays a spinner via [isSwitchingCourse] instead of
      // blanking it, so switching between two already-familiar courses
      // doesn't flash blank-then-repopulate). A same-course reload
      // (pull-to-refresh, [ensureRoadmapLoaded]'s self-heal) also just keeps
      // the existing data visible, as before.
      buildLoadingState: () => state.copyWith(status: CourseRoadmapStatus.loading),
      onFailure: (error) {
        if (_switchingToCourseId == courseId) _switchingToCourseId = null;
        emit(
          state.copyWith(
            status: CourseRoadmapStatus.failure,
            errorMessage: error,
          ),
        );
      },
      onSuccess: (roadmap) {
        if (_switchingToCourseId == courseId) _switchingToCourseId = null;
        _hasLoadedThisSession = true;
        // Nhánh A/B nội dung do server chia, nhớ lại để MỌI event của khoá /
        // bài / keypoint đóng dấu được nó. Không có dấu này thì bảng kết quả
        // A/B toàn số 0 và trông y như "hai bản không khác gì nhau".
        ContentExperimentTracker.instance.remember(
          courseId: courseId,
          key: roadmap.contentExperiment?.key,
          arm: roadmap.contentExperiment?.arm,
        );
        final selection = roadmap.autoSelectedLesson(fallbackLevel: state.currentCourseLevel);
        final selectedLesson = selection.key;
        final selectedLevel = selection.value;
        _cachedLessonAction = selectedLesson.id.isEmpty ? null : selectedLesson;
        // currentLevelProgress is only ever written by
        // AchievenmentProgressCubit.loadCourseLevelProgress — which, on this
        // flow, runs only AFTER a keypoint completes — and it's hydrated
        // across restarts. So when the roadmap points at a different course
        // (course switch, cold start), it still holds the PREVIOUS course's
        // badge/title/progress, and the badge screens
        // (keypoint_complete/badge_progress) render that other course first,
        // then visibly swap once the post-completion fan-out lands. Clear the
        // mismatched entity so they can never show another course's badge,
        // and fetch this course's level progress NOW so the completion screen
        // has the right data the moment it appears.
        final bool levelProgressIsForThisCourse = state.currentLevelProgress.courseId == roadmap.courseId;
        emit(
          state.copyWith(
            status: CourseRoadmapStatus.success,
            roadmap: roadmap,
            currentLesson: selectedLesson,
            currentCourseLevel: selectedLevel,
            currentLevelProgress: levelProgressIsForThisCourse ? state.currentLevelProgress : const CourseLevelProgressEntity(),
          ),
        );
        if (!levelProgressIsForThisCourse) {
          AppDI.injector.get<AchievenmentProgressCubit>().loadCourseLevelProgress(roadmap.courseId);
        }
      },
    );
  }
}
