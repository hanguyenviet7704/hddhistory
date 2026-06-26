part of '../../../course.dart';

enum CourseStatus { initial, loading, success, failure }

@freezed
abstract class CourseState with _$CourseState {
  const factory CourseState({
    @Default(CourseStatus.initial) CourseStatus status,
    @Default([]) List<CourseEntity> courses,
    @Default(0) int selectedTabIndex,
    @Default('unknown') String allCourseSource,
    @Default(false) bool isSearchActive,
    @Default('') String searchQuery,
    @Default(-1) int selectedCategoryIndex,
    @Default([]) List<String> searchHistory,
    @Default(false) bool isLoadingHistory,
    CourseEntity? selectedItem,
    String? errorMessage,
  }) = _CourseState;

  factory CourseState.initial() => CourseState();

  factory CourseState.fromJson(Map<String, dynamic> json) => _$CourseStateFromJson(json);
}
