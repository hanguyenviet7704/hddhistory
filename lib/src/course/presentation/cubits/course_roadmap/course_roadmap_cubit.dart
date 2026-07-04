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

  CourseRoadmapCubit(
    this._getRoadmapUseCase,
  ) : super(CourseRoadmapState.initial());

  @override
  CourseRoadmapState fromJson(Map<String, dynamic> json) => CourseRoadmapState.fromJson(json);

  @override
  Map<String, dynamic> toJson(CourseRoadmapState state) => state.toJson();

  void reset() {
    _hasLoadedThisSession = false;
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
    if (courseId.isEmpty) {
      courseId = state.roadmap.courseId;
    }
    if (courseId.isEmpty) return;

    // Opening a course's roadmap is the universal "view" signal — record it so
    // the course surfaces in the search screen's "Recent" list.
    AppDI.injector.get<CourseCubit>().recordCourseView(courseId);

    await runUseCase<RoadmapEntity>(
      usecase: () => _getRoadmapUseCase(courseId),
      buildLoadingState: () => state.copyWith(status: CourseRoadmapStatus.loading),
      onFailure: (error) {
        emit(
          state.copyWith(
            status: CourseRoadmapStatus.failure,
            errorMessage: error,
          ),
        );
      },
      onSuccess: (roadmap) {
        _hasLoadedThisSession = true;
        final selection = roadmap.autoSelectedLesson(fallbackLevel: state.currentCourseLevel);
        final selectedLesson = selection.key;
        final selectedLevel = selection.value;
        _cachedLessonAction = selectedLesson.id.isEmpty ? null : selectedLesson;
        emit(
          state.copyWith(
            status: CourseRoadmapStatus.success,
            roadmap: roadmap,
            currentLesson: selectedLesson,
            currentCourseLevel: selectedLevel,
          ),
        );
      },
    );
  }
}
