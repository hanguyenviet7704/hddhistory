part of '../../../course.dart';

@lazySingleton
class CourseCubit extends Cubit<CourseState> with CubitUseCaseHandlerMixin<CourseState> {
  final GetSearchHistoryUseCase _getSearchHistory;
  final SaveSearchQueryUseCase _saveSearchQuery;
  final ClearSearchHistoryUseCase _clearSearchHistory;

  CourseCubit(
    this._getSearchHistory,
    this._saveSearchQuery,
    this._clearSearchHistory,
  ) : super(CourseState.initial());

  final TextEditingController searchController = TextEditingController();

  void setCourses(List<CourseEntity> courses) => emit(state.copyWith(courses: courses));

  void selectTab(int index) => emit(state.copyWith(selectedTabIndex: index));

  void setAllCourseSource(String source) => emit(state.copyWith(allCourseSource: source));

  void activateSearch() {
    emit(state.copyWith(isSearchActive: true));
    loadSearchHistory();
  }

  void clearSearch() {
    searchController.clear();
    emit(state.copyWith(isSearchActive: false, searchQuery: ''));
  }

  void onSearchChanged(String query) => emit(state.copyWith(searchQuery: query));

  void updateSearch(String query) {
    searchController.text = query;
    searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: query.length),
    );
    emit(state.copyWith(searchQuery: query));
  }

  void selectCategory(int index) => emit(state.copyWith(selectedCategoryIndex: index));

  Future<void> loadSearchHistory() async {
    emit(state.copyWith(isLoadingHistory: true));
    final result = await _getSearchHistory(unit).run();
    result.fold(
      (_) => emit(state.copyWith(isLoadingHistory: false)),
      (history) => emit(state.copyWith(isLoadingHistory: false, searchHistory: history)),
    );
  }

  Future<void> saveSearchQuery(String query) async {
    if (query.trim().isEmpty) return;
    final trimmed = query.trim();
    // Optimistically update local state (dedup + cap at 10)
    final updated = [trimmed, ...state.searchHistory.where((q) => q != trimmed)].take(10).toList();
    emit(state.copyWith(searchHistory: updated));
    // Fire-and-forget: persist to server
    await _saveSearchQuery(trimmed).run();
  }

  Future<void> clearSearchHistory() async {
    emit(state.copyWith(searchHistory: []));
    await _clearSearchHistory(unit).run();
  }

  @override
  Future<void> close() {
    searchController.dispose();
    return super.close();
  }
}
