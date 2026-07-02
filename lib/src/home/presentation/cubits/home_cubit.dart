part of '../../home.dart';

@lazySingleton
class HomeCubit extends Cubit<HomeState> with CubitUseCaseHandlerMixin<HomeState> {
  final GetAllSkillsetsUseCase _getAllUseCase;
  final GetSkillsetUseCase _getUseCase;
  final GetRandomQuoteUseCase _getRandomQuoteUseCase;
  final GetSuggestCoursesUseCase _getSuggestCoursesUseCase;

  HomeCubit(
    this._getAllUseCase,
    this._getUseCase,
    this._getRandomQuoteUseCase,
    this._getSuggestCoursesUseCase,
  ) : super(HomeState.initial());

  bool _isInitialized = false;
  DateTime? _lastInitializedAt;
  Future<void>? _initInFlight;

  /// How long a successful init stays "fresh". Within this window an
  /// `isInit` re-entry (splash/auth/handoff/pull-to-refresh) is skipped so we
  /// don't refetch all 5 endpoints again. A [force] request always refetches.
  static const _initFreshnessWindow = Duration(seconds: 45);

  Future<void> initializeData({bool isInit = false, bool force = false}) async {
    // De-dupe concurrent callers (prewarm + handoff + page mount) onto the SAME
    // in-flight fetch instead of each starting its own.
    final inFlight = _initInFlight;
    if (inFlight != null) return inFlight;
    if (!force) {
      // First-load guard: only the initial call (or an explicit isInit) may
      // load when not yet initialized.
      if (_isInitialized && !isInit) return;
      // Freshness guard: a very recent SUCCESSFUL init is reused instead of
      // hitting all endpoints again for another isInit re-entry.
      final lastInitializedAt = _lastInitializedAt;
      if (_isInitialized && lastInitializedAt != null && DateTime.now().difference(lastInitializedAt) < _initFreshnessWindow) {
        return;
      }
    }
    final future = _runInitializeData();
    _initInFlight = future;
    try {
      await future;
    } finally {
      _initInFlight = null;
    }
  }

  Future<void> _runInitializeData() async {
    // Load both courses and skillsets]
    await Future.wait<void>([
      loadAllSkillsets(isInit: true),
      loadRandomQuote(),
      loadSuggestCourses(),
      AppDI.injector.get<ProgressCubit>().loadUserProgressMyCourses(isInit: true, recent: true),
      AppDI.injector.get<ProfileCubit>().loadUser(),
    ]);
    // Only mark the init done + "fresh" when the CRITICAL dataset (skillsets)
    // actually loaded. A transient failure — e.g. the onboarding prewarm fires
    // before the anonymous token is attached, so skillsets 401 → empty — must
    // NOT be cached as fresh, otherwise the freshness guard blocks every retry
    // and Home/Explore stays blank with no API re-fire.
    final loadedOk = state.skillsets.isNotEmpty;
    _isInitialized = loadedOk;
    _lastInitializedAt = loadedOk ? DateTime.now() : null;
  }

  static final _fallbackQuote = QuoteEntity(
    content: const BaseMultiLanguage(
      en: "Life isn't about finding yourself.\nLife is about creating yourself.",
      vi: 'Cuộc sống không phải là tìm thấy bản thân.\nCuộc sống là tạo ra bản thân.',
    ),
  );

  Future<void> loadRandomQuote() async {
    await runUseCase<QuoteEntity>(
      usecase: () => _getRandomQuoteUseCase(),
      onFailure: (error) => emit(state.copyWith(
        errorMessage: error,
        quote: _fallbackQuote,
      )),
      onSuccess: (quote) => emit(state.copyWith(quote: quote)),
    );
  }

  Future<void> loadSuggestCourses() async {
    await runUseCaseList<SuggestedCourseEntity>(
      usecase: () => _getSuggestCoursesUseCase(6),
      onFailure: (error) => emit(state.copyWith(errorMessage: error)),
      onSuccess: (courses) => emit(state.copyWith(suggestedCourses: courses)),
    );
  }

  void resetSelection({
    int skillsetIndex = 0,
    int courseIndex = 0,
  }) {
    emit(
      state.copyWith(
        selectedSkillsetIndex: skillsetIndex,
        selectedCourseIndex: courseIndex,
      ),
    );
  }

  void selectSkillsetIndex(int index) => emit(state.copyWith(selectedSkillsetIndex: index));
  void selectSkillset(SkillsetEntity skillset) {
    int skillSetIndex = state.skillsets.indexWhere((s) => s.id == skillset.id);
    if (skillSetIndex == -1) return;
    selectSkillsetIndex(skillSetIndex);
  }

  void selectCourseIndex(int index) {
    emit(state.copyWith(selectedCourseIndex: index));
    AppDI.injector.get<CourseRoadmapCubit>().loadRoadmap(courseId: state.currentCourse.id);
  }

  void selectCourse(CourseEntity course) {
    int courseIndex = state.currentSkillset.courses.indexWhere((c) => c.id == course.id);
    if (courseIndex == -1) return;
    selectCourseIndex(courseIndex);
  }

  void selectCourseFromCourseId(String courseId) {
    final skillset = state.skillsets.firstWhere(
      (s) => s.courses.any((c) => c.id == courseId),
      orElse: () => SkillsetEntity(),
    );
    if (skillset.id.isEmpty) return;
    selectSkillset(skillset);
    int courseIndex = skillset.courses.indexWhere((c) => c.id == courseId);
    if (courseIndex == -1) return;
    selectCourseIndex(courseIndex);
  }

  bool trySelectCourseFromCourseId(String courseId) {
    final skillset = state.skillsets.firstWhere(
      (s) => s.courses.any((c) => c.id == courseId),
      orElse: () => SkillsetEntity(),
    );
    if (skillset.id.isEmpty) return false;

    selectSkillset(skillset);
    final courseIndex = skillset.courses.indexWhere((c) => c.id == courseId);
    if (courseIndex == -1) return false;

    selectCourseIndex(courseIndex);
    return true;
  }

  Future<void> loadAllSkillsets({
    bool isInit = false,
  }) async {
    // Prevent multiple simultaneous loads
    if (!isInit && state.status == HomeStatus.loading) return;

    // Prevent loading if already on last page (unless it's init)
    if (!isInit && state.pageData.isLastPage) return;

    emit(state.copyWith(status: HomeStatus.loading));

    PageBreakRequest<SkillsetFilterRequest> pageRequest;
    pageRequest = isInit
        ? const PageBreakRequest<SkillsetFilterRequest>(
            order: PageBreakOrder.asc,
          )
        : PageBreakRequest<SkillsetFilterRequest>(
            page: state.pageData.nextPage,
            order: PageBreakOrder.asc,
          );

    await runUseCasePageBreak<SkillsetEntity>(
      usecase: () => _getAllUseCase(pageRequest),
      currentPageData: state.pageData,
      isInit: isInit,
      buildLoadingState: () => state.copyWith(status: HomeStatus.loading),
      onFailure: (error) {
        emit(
          state.copyWith(
            status: HomeStatus.failure,
            errorMessage: error,
          ),
        );
      },
      onSuccess: (pageData) {
        emit(
          state.copyWith(
            status: HomeStatus.success,
            pageData: pageData,
          ),
        );
      },
    );
  }

  Future<void> loadSkillset(String id) async {
    await runUseCase<SkillsetEntity>(
      usecase: () => _getUseCase(id),
      buildLoadingState: () => state.copyWith(status: HomeStatus.loading),
      onFailure: (error) {
        emit(
          state.copyWith(
            status: HomeStatus.failure,
            errorMessage: error,
          ),
        );
      },
      onSuccess: (item) {
        updatePageBreakItem(
          currentPageData: state.pageData,
          updatedItem: item,
          getId: (item) => item.id,
          onSuccess: (pageData) => emit(state.copyWith(status: HomeStatus.success, pageData: pageData)),
        );
      },
    );
  }
}
