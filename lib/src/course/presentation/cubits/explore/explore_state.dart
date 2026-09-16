part of '../../../course.dart';

enum ExploreStatus { initial, loading, success, failure }

@freezed
abstract class ExploreState with _$ExploreState {
  const factory ExploreState({
    @Default(ExploreStatus.initial) ExploreStatus status,

    /// Sections in the order the server decided. The tab renders this list as
    /// given — it does not sort, filter or insert.
    @Default([]) List<ExploreSectionEntity> sections,

    /// This session's shuffle seed. Generated once on cold start and sent with
    /// every fetch, so the strips keep one arrangement for the whole session
    /// instead of reshuffling under the reader on each refetch.
    @Default(0) int seed,
    String? errorMessage,
  }) = _ExploreState;
}
