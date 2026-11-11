part of '../../../course.dart';

enum ExploreStatus { initial, loading, success, failure }

@freezed
abstract class ExploreState with _$ExploreState {
  const factory ExploreState({
    @Default(ExploreStatus.initial) ExploreStatus status,

    /// Sections in the order the server decided, with the courses INSIDE each
    /// one already shuffled for display. The tab renders this list as given —
    /// it does not sort, filter or reorder.
    @Default([]) List<ExploreSectionEntity> sections,
    String? errorMessage,
  }) = _ExploreState;
}
