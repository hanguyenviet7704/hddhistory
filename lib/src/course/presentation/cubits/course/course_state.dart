part of '../../../course.dart';

enum CourseStatus { initial, loading, success, failure }

/// Explore view modes. [all] = every skillset stacked as scrollspy sections;
/// [myCourses] = a flat grid of the user's enrolled courses.
enum CourseExploreMode { all, myCourses }

@freezed
abstract class CourseState with _$CourseState {
  const factory CourseState({
    @Default(CourseStatus.initial) CourseStatus status,
    @Default([]) List<CourseEntity> courses,
    @Default(0) int selectedTabIndex,
    @Default('unknown') String allCourseSource,
    @Default(false) bool isSearchActive,
    @Default('') String searchQuery,
    @Default(CourseExploreMode.all) CourseExploreMode exploreMode,
    // Skillset index whose chip is highlighted in [CourseExploreMode.all].
    // -1 = no chip highlighted ("out menu").
    @Default(-1) int activeSkillsetIndex,
    // Bumped to request the Explore list scroll to [activeSkillsetIndex]
    // (or top when it is -1). The list owns its scroll controller and reacts to
    // changes of this value; scrollspy updates don't bump it.
    @Default(0) int exploreScrollNonce,
    @Default([]) List<CourseEntity> recentCourses,
    @Default(false) bool isLoadingRecent,
    CourseEntity? selectedItem,
    String? errorMessage,
  }) = _CourseState;

  factory CourseState.initial() => CourseState();

  factory CourseState.fromJson(Map<String, dynamic> json) => _$CourseStateFromJson(json);
}
