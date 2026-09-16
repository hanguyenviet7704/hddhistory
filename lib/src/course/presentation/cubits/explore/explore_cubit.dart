part of '../../../course.dart';

@lazySingleton
class ExploreCubit extends Cubit<ExploreState> with CubitUseCaseHandlerMixin<ExploreState> {
  final GetExploreSectionsUseCase _getExploreSections;

  ExploreCubit(this._getExploreSections) : super(const ExploreState());

  final Random _random = Random();

  Future<void>? _inFlight;

  /// Loads the tab if it has nothing to show, and reshuffles if it has.
  ///
  /// Called on every entry to the tab, which is what makes the strips come back
  /// in a different order each visit ("random thứ tự mỗi lần user vào"). The
  /// reshuffle is local, so re-entering costs nothing — doing it server-side
  /// would mean a fetch per visit for an effect that is purely presentational.
  Future<void> ensureExploreDataLoaded() {
    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;
    if (state.status == ExploreStatus.success && state.sections.isNotEmpty) {
      reshuffle();
      return Future.value();
    }
    return refresh();
  }

  /// Fetches unconditionally — pull to refresh, and the retry button on the
  /// failure state.
  Future<void> refresh() {
    final future = _load().whenComplete(() => _inFlight = null);
    _inFlight = future;
    return future;
  }

  /// Reorders the courses inside each strip.
  ///
  /// The weekly-popular strip is left alone: its order IS its content (#1 to
  /// #3), so shuffling it would turn a ranking into a lie.
  void reshuffle() {
    if (state.sections.isEmpty) return;
    emit(state.copyWith(sections: _shuffled(state.sections)));
  }

  List<ExploreSectionEntity> _shuffled(List<ExploreSectionEntity> sections) {
    return [
      for (final section in sections)
        if (section.type == ExploreSectionType.weeklyTop)
          section
        else
          section.copyWith(courses: [...section.courses]..shuffle(_random)),
    ];
  }

  Future<void> _load() async {
    emit(state.copyWith(status: ExploreStatus.loading, errorMessage: null));

    await runUseCaseList<ExploreSectionEntity>(
      usecase: () => _getExploreSections(unit),
      onFailure: (errorMessage) => emit(
        state.copyWith(
          status: ExploreStatus.failure,
          errorMessage: errorMessage,
        ),
      ),
      onSuccess: (sections) => emit(
        state.copyWith(status: ExploreStatus.success, sections: _shuffled(sections)),
      ),
    );
  }
}
