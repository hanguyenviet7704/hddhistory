part of '../../../course.dart';

@lazySingleton
class CourseCubit extends Cubit<CourseState> with CubitUseCaseHandlerMixin<CourseState> {
  final GetRecentCoursesUseCase _getRecentCourses;
  final RecordCourseViewUseCase _recordCourseView;
  final ClearRecentCoursesUseCase _clearRecentCourses;
  final GetAllCoursesUseCase _getAllCourses;

  CourseCubit(
    this._getRecentCourses,
    this._recordCourseView,
    this._clearRecentCourses,
    this._getAllCourses,
  ) : super(CourseState.initial());

  final TextEditingController searchController = TextEditingController();

  /// Debounce so we hit the search API once the user pauses typing.
  Timer? _searchDebounce;

  /// The last query whose search-view event (result / no-result) was fired.
  /// Fires the view event ONCE per distinct query so a rebuild — or the same
  /// query being re-run — never double-counts. Reset when search is cleared/
  /// exited so re-searching the same term in a new session fires again.
  String? _lastTrackedSearchQuery;

  void setCourses(List<CourseEntity> courses) => emit(state.copyWith(courses: courses));

  void selectTab(int index) => emit(state.copyWith(selectedTabIndex: index));

  void setAllCourseSource(String source) => emit(state.copyWith(allCourseSource: source));

  void activateSearch() {
    emit(state.copyWith(isSearchActive: true));
    loadRecentCourses();
  }

  /// Clears the entered text but stays in search mode (shows "Recent").
  /// Maps to the in-field "X" per the search-flow spec.
  void clearSearchText() {
    _searchDebounce?.cancel();
    _lastTrackedSearchQuery = null;
    searchController.clear();
    emit(state.copyWith(searchQuery: '', courses: const [], status: CourseStatus.initial));
  }

  /// Exits search mode entirely, returning to the course grid.
  void deactivateSearch() {
    _searchDebounce?.cancel();
    _lastTrackedSearchQuery = null;
    searchController.clear();
    emit(
      state.copyWith(
        isSearchActive: false,
        searchQuery: '',
        courses: const [],
        status: CourseStatus.initial,
      ),
    );
  }

  /// Backwards-compatible alias for fully exiting search.
  void clearSearch() => deactivateSearch();

  void onSearchChanged(String query) {
    emit(state.copyWith(searchQuery: query));
    _scheduleSearch(query);
  }

  void updateSearch(String query) {
    searchController.text = query;
    searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: query.length),
    );
    emit(state.copyWith(searchQuery: query));
    _scheduleSearch(query);
  }

  /// Debounced server-side search: matches title/description via the courses
  /// API (`GET /courses?search=`). Coming-soon courses are excluded per spec.
  void _scheduleSearch(String query) {
    _searchDebounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      emit(state.copyWith(courses: const [], status: CourseStatus.initial));
      return;
    }
    _searchDebounce = Timer(
      const Duration(milliseconds: 350),
      () => _runSearch(trimmed),
    );
  }

  Future<void> _runSearch(String query) async {
    emit(state.copyWith(status: CourseStatus.loading));
    final result = await _getAllCourses(
      PageBreakRequest<CourseFilterRequest>(search: query, limit: 50),
    ).run();
    // Drop stale responses if the query changed while awaiting.
    if (query != state.searchQuery.trim()) return;
    result.fold(
      (_) => emit(state.copyWith(status: CourseStatus.failure, courses: const [])),
      (page) {
        final results = page.items.where((c) => !c.isComingSoonNow).toList();
        emit(state.copyWith(status: CourseStatus.success, courses: results));
        _trackSearchView(query, hasResults: results.isNotEmpty);
      },
    );
  }

  /// Fires the search result / no-result view event once per distinct query.
  /// Called from [_runSearch]'s success branch (never from a widget build), so
  /// it can't be re-fired by a rebuild.
  void _trackSearchView(String query, {required bool hasResults}) {
    if (query == _lastTrackedSearchQuery) return;
    _lastTrackedSearchQuery = query;
    ExploreTracking.track(
      hasResults ? TrackingKey.exploreSearchResultView : TrackingKey.exploreSearchNoresultView,
      parameters: {'search_term': query},
    );
  }

  /// Switches Explore to the "My courses" filtered grid.
  void showMyCourses() => emit(state.copyWith(exploreMode: CourseExploreMode.myCourses));

  /// Switches Explore to the "all courses" sections and asks the list to scroll
  /// to skillset [index], lighting its chip. Bumping [exploreScrollNonce] is the
  /// scroll request — the list (which owns its scroll controller) listens for it.
  /// Used by chip taps and onboarding deep-links.
  void jumpToSkillset(int index) {
    emit(
      state.copyWith(
        exploreMode: CourseExploreMode.all,
        activeSkillsetIndex: index,
        exploreScrollNonce: state.exploreScrollNonce + 1,
      ),
    );
  }

  /// Scrollspy callback — highlights the chip of the section at the viewport
  /// middle. Emits only on change to avoid per-frame churn. Does NOT bump the
  /// scroll nonce, so reporting position never triggers a counter-scroll.
  void onActiveSectionChanged(int index) {
    if (state.exploreMode != CourseExploreMode.all) return;
    if (index == state.activeSkillsetIndex) return;
    emit(state.copyWith(activeSkillsetIndex: index));
  }

  /// Resets Explore to the default "all courses / out menu" state: all sections,
  /// no chip highlighted, scrolled to the top. Called on every Explore entry.
  void resetExploreToAll() {
    emit(
      state.copyWith(
        exploreMode: CourseExploreMode.all,
        activeSkillsetIndex: -1,
        exploreScrollNonce: state.exploreScrollNonce + 1,
      ),
    );
  }

  /// Loads the "Recent" list — recently-viewed courses (Figma search screen).
  Future<void> loadRecentCourses() async {
    emit(state.copyWith(isLoadingRecent: true));
    final result = await _getRecentCourses(unit).run();
    result.fold(
      (_) => emit(state.copyWith(isLoadingRecent: false)),
      (courses) => emit(state.copyWith(isLoadingRecent: false, recentCourses: courses)),
    );
  }

  /// Records that the user opened a course, so it appears in "Recent".
  /// Fire-and-forget — failures are silent.
  Future<void> recordCourseView(String courseId) async {
    if (courseId.trim().isEmpty) return;
    await _recordCourseView(courseId.trim()).run();
  }

  Future<void> clearRecentCourses() async {
    emit(state.copyWith(recentCourses: []));
    await _clearRecentCourses(unit).run();
  }

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    searchController.dispose();
    return super.close();
  }
}
