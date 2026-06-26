part of '../../../course.dart';

@lazySingleton
class CourseCubit extends Cubit<CourseState> with CubitUseCaseHandlerMixin<CourseState> {
  CourseCubit() : super(CourseState.initial());

  final TextEditingController searchController = TextEditingController();

  void setCourses(List<CourseEntity> courses) => emit(state.copyWith(courses: courses));

  void selectTab(int index) => emit(state.copyWith(selectedTabIndex: index));

  void setAllCourseSource(String source) => emit(state.copyWith(allCourseSource: source));

  void activateSearch() => emit(state.copyWith(isSearchActive: true));

  void clearSearch() {
    searchController.clear();
    emit(state.copyWith(isSearchActive: false, searchQuery: ''));
  }

  void onSearchChanged(String query) => emit(state.copyWith(searchQuery: query));

  void selectCategory(int index) => emit(state.copyWith(selectedCategoryIndex: index));

  @override
  Future<void> close() {
    searchController.dispose();
    return super.close();
  }
}
